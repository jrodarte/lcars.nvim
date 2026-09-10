-- Python execution-environment state: interpreter, venv, version, tooling.
-- Detection is cached per project root and refreshed only on real changes.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local cached_root = nil
local version_job = nil

local function set(fields)
  for k, v in pairs(fields) do
    state.python[k] = v
  end
end

local function parse_pyvenv(content)
  if not content then
    return nil
  end
  local v = content:match("version_info%s*=%s*([%d%.]+)") or content:match("version%s*=%s*([%d%.]+)")
  if v then
    v = v:gsub("%.final.*$", ""):gsub("%.$", "")
    -- keep at most three components
    local a, b, c = v:match("^(%d+)%.(%d+)%.?(%d*)")
    if a and b then
      return c ~= "" and (a .. "." .. b .. "." .. c) or (a .. "." .. b)
    end
    return v
  end
  return nil
end

local function detect_version(exe, venv_path)
  if venv_path then
    util.read_file(venv_path .. "/pyvenv.cfg", function(content)
      local v = parse_pyvenv(content)
      if v then
        set({ version = v })
        util.redrawstatus()
      elseif exe then
        M.version_from_exe(exe)
      end
    end)
  elseif exe then
    M.version_from_exe(exe)
  end
end

function M.version_from_exe(exe)
  if version_job == exe then
    return
  end
  version_job = exe
  util.system({ exe, "--version" }, {}, function(code, out)
    version_job = nil
    if code == 0 then
      local v = out:match("(%d+%.%d+%.?%d*)")
      if v then
        set({ version = v })
        util.redrawstatus()
      end
    end
  end)
end

local function lsp_python_path()
  for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
    local p = vim.tbl_get(client, "settings", "python", "pythonPath")
    if p and util.exists(p) then
      return p
    end
  end
  for _, client in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
    local p = vim.tbl_get(client, "settings", "python", "pythonPath")
    if p and util.exists(p) then
      return p
    end
  end
  return nil
end

local function formatter_for_python()
  local conform = package.loaded["conform"]
  if conform then
    local ok, list = pcall(conform.list_formatters_for_buffer, 0)
    if ok and list and #list > 0 then
      return table.concat(list, "+"):upper()
    end
    local by_ft = vim.tbl_get(conform, "formatters_by_ft", "python")
    if type(by_ft) == "table" and #by_ft > 0 then
      return tostring(by_ft[1]):upper()
    end
  end
  return nil
end

---@param force? boolean
function M.refresh(force)
  local root = util.root()
  if not force and cached_root == root and state.python.exe then
    return
  end
  cached_root = root
  local prev_venv = state.python.venv_path

  local venv_path, kind, name
  local candidates = {
    { vim.env.VIRTUAL_ENV, "venv" },
    { vim.env.CONDA_PREFIX, "conda" },
    { root .. "/.venv", "venv" },
    { root .. "/venv", "venv" },
    { root .. "/env", "venv" },
  }
  for _, cand in ipairs(candidates) do
    local path = cand[1]
    if path and path ~= "" and util.exists(path .. "/bin/python") then
      venv_path, kind = path, cand[2]
      break
    end
  end

  local exe
  if venv_path then
    exe = venv_path .. "/bin/python"
    if kind == "conda" then
      name = vim.env.CONDA_DEFAULT_ENV or vim.fn.fnamemodify(venv_path, ":t")
    else
      -- ".venv" is uninformative; use the project name instead
      local base = vim.fn.fnamemodify(venv_path, ":t")
      name = (base == ".venv" or base == "venv" or base == "env") and util.project_name(root) or base
    end
  else
    exe = lsp_python_path()
    if exe then
      venv_path = vim.fn.fnamemodify(exe, ":h:h")
      kind = "lsp"
      name = vim.fn.fnamemodify(venv_path, ":t")
      if name == ".venv" then
        name = util.project_name(root)
      end
    else
      local sys = vim.fn.exepath("python3")
      exe = sys ~= "" and sys or nil
      kind = exe and "system" or nil
      name = nil
    end
  end

  local ruff = false
  if venv_path and util.exists(venv_path .. "/bin/ruff") then
    ruff = true
  elseif vim.fn.executable("ruff") == 1 then
    ruff = true
  end

  set({
    exe = exe,
    venv_path = venv_path,
    venv = name,
    kind = kind,
    ruff = ruff,
    formatter = formatter_for_python(),
    version = nil,
  })
  detect_version(exe, venv_path)

  -- Poetry: only if no in-project venv was found and pyproject is poetry-managed
  if not venv_path and util.exists(root .. "/pyproject.toml") and vim.fn.executable("poetry") == 1 then
    util.read_file(root .. "/pyproject.toml", function(content)
      if content and content:find("%[tool%.poetry%]") then
        util.system({ "poetry", "env", "info", "-p" }, { cwd = root }, function(code, out)
          local p = vim.trim(out)
          if code == 0 and p ~= "" and util.exists(p .. "/bin/python") then
            set({ venv_path = p, kind = "poetry", venv = vim.fn.fnamemodify(p, ":t"), exe = p .. "/bin/python" })
            detect_version(p .. "/bin/python", p)
            util.redrawstatus()
          end
        end)
      end
    end)
  end

  if prev_venv and venv_path and prev_venv ~= venv_path then
    require("lcars.notifications").event(
      "python-env",
      "PYTHON EXECUTION ENVIRONMENT UPDATED · " .. (name or ""):upper()
    )
  end
  util.redrawstatus()
end

---@param group integer augroup
function M.setup(group)
  cached_root = nil
  vim.api.nvim_create_autocmd({ "DirChanged", "FocusGained" }, {
    group = group,
    callback = function()
      M.refresh(false)
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      if util.root() ~= cached_root then
        M.refresh(false)
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client and (client.name == "basedpyright" or client.name == "pyright") and not state.python.venv_path then
        M.refresh(true)
      end
    end,
  })
  M.refresh(true)
end

function M.teardown()
  cached_root = nil
end

--- Short label for UI: "PY 3.12 · distillery"
function M.label(short)
  local p = state.python
  if not p.exe then
    return short and "PY N/A" or "PYTHON N/A"
  end
  local v = p.version and (short and p.version:match("^%d+%.%d+") or p.version) or "?"
  local out = (short and "PY " or "PYTHON ") .. v
  if p.venv and not short then
    out = out .. " · " .. p.venv
  end
  return out
end

return M
