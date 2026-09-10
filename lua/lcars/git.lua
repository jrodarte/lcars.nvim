-- Git telemetry: branch, worktree, working-tree counts, ahead/behind.
-- Per-buffer hunk counts come from Gitsigns (free); repository-level data
-- comes from one throttled async `git status --porcelain=v2 --branch`.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local have_git = vim.fn.executable("git") == 1
local roots = {} ---@type table<string, {worktree: boolean, checked: boolean}>
local first_branch_seen = false

local function parse_status(out)
  local g = state.git
  local modified, staged, untracked, ahead, behind = 0, 0, 0, 0, 0
  local head
  for line in out:gmatch("[^\n]+") do
    local c = line:sub(1, 1)
    if c == "#" then
      local h = line:match("^# branch%.head (.+)$")
      if h then
        head = h
      end
      local a, b = line:match("^# branch%.ab %+(%d+) %-(%d+)$")
      if a then
        ahead, behind = tonumber(a), tonumber(b)
      end
    elseif c == "1" or c == "2" then
      local xy = line:match("^[12] (..)")
      if xy then
        if xy:sub(1, 1) ~= "." then
          staged = staged + 1
        end
        if xy:sub(2, 2) ~= "." then
          modified = modified + 1
        end
      end
    elseif c == "u" then
      modified = modified + 1
    elseif c == "?" then
      untracked = untracked + 1
    end
  end
  g.modified, g.staged, g.untracked, g.ahead, g.behind = modified, staged, untracked, ahead, behind
  g.dirty = (modified + staged + untracked) > 0
  if head and head ~= "(detached)" then
    if first_branch_seen and g.branch and g.branch ~= head then
      require("lcars.notifications").event("git-branch", "DEVELOPMENT BRANCH UPDATED · " .. head:upper())
    end
    g.branch = head
    first_branch_seen = true
  elseif head == "(detached)" then
    g.branch = "DETACHED"
  end
end

local function check_worktree(root)
  if roots[root] and roots[root].checked then
    state.git.worktree = roots[root].worktree
    return
  end
  roots[root] = { worktree = false, checked = false }
  util.system({ "git", "rev-parse", "--git-dir", "--git-common-dir" }, { cwd = root }, function(code, out)
    if code ~= 0 then
      roots[root] = { worktree = false, checked = true }
      return
    end
    local lines = vim.split(vim.trim(out), "\n")
    local gitdir, common = lines[1] or "", lines[2] or ""
    local function norm(p)
      if p == "" then
        return p
      end
      if not p:match("^/") then
        p = root .. "/" .. p
      end
      return vim.fs.normalize(p)
    end
    local wt = norm(gitdir) ~= norm(common)
    roots[root] = { worktree = wt, checked = true }
    if state.git.root == root then
      state.git.worktree = wt
      util.redrawstatus()
    end
  end)
end

local function do_refresh()
  if not have_git or not state.enabled then
    return
  end
  local root = util.root()
  if not root then
    return
  end
  util.system(
    { "git", "status", "--porcelain=v2", "--branch", "--untracked-files=normal" },
    { cwd = root },
    function(code, out)
      if not state.enabled then
        return
      end
      if code ~= 0 then
        if state.git.root == root then
          state.git.available = false
          state.git.branch = nil
        end
        return
      end
      if state.git.root ~= root then
        -- project switch: don't announce a "branch change" across projects
        first_branch_seen = false
        state.git.branch = nil
      end
      state.git.root = root
      state.git.available = true
      parse_status(out)
      check_worktree(root)
      util.redrawstatus()
    end
  )
end

M.refresh = util.throttle(2500, do_refresh)

--- Per-buffer hunk stats from Gitsigns (no subprocess).
---@return {added: number, changed: number, removed: number}?
function M.buffer_diff()
  local d = vim.b.gitsigns_status_dict
  if not d then
    return nil
  end
  return { added = d.added or 0, changed = d.changed or 0, removed = d.removed or 0 }
end

--- Best-known branch: cached repo status first, Gitsigns head as fallback.
function M.branch()
  if state.git.branch then
    return state.git.branch
  end
  local head = vim.b.gitsigns_head
  if head and head ~= "" then
    return head
  end
  return nil
end

---@param group integer
function M.setup(group)
  if not have_git then
    return
  end
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "DirChanged", "TermClose" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "GitSignsUpdate", "GitSignsChanged", "LazyGitClosed" },
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      if util.root() ~= state.git.root then
        M.refresh()
      end
    end,
  })
  do_refresh()
end

function M.teardown()
  roots = {}
  first_branch_seen = false
end

return M
