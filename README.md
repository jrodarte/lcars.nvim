# lcars.nvim — Neovim as a Voyager-era Starfleet workstation

A self-contained LCARS UI subsystem for [LazyVim](https://www.lazyvim.org): colorscheme,
segmented statusline, winbar, dashboard boot sequence, notifications, picker styling,
Python/Git/LSP/test/DAP/AI telemetry, Red Alert, and a heartbeat that keeps the console
alive. It can be switched on and off while Neovim is running; `:LCARSOff` is a real
teardown that puts your previous colorscheme, lualine, bufferline, winbar, cursor and
notification style back.

## Install (lazy.nvim / LazyVim)

`lua/plugins/lcars.lua`:

```lua
return {
  {
    "jrodarte/lcars.nvim",
    import = "lcars.plugins", -- ships the Snacks + which-key integration specs
    opts = {
      persist_mode = true,             -- remember :LCARSOn / :LCARSOff across restarts
      fallback_colorscheme = "tokyonight",
      animations = { enabled = true, interval = 750, pause_unfocused = true },
      red_alert = { enabled = true, automatic = false, threshold = 1 },
    },
  },
}
```

Requirements: Neovim 0.10+, truecolor, a Nerd Font. Snacks, lualine, bufferline,
which-key, trouble and gitsigns are optional but used when present (LazyVim has them all).
Run `:checkhealth lcars` after installing.

```
:LCARSOn / :LCARSOff / :LCARSToggle     <leader>vv
:LCARSStatus                             <leader>vs
:LCARS            (control center)       <leader>vc
:LCARSRedAlert                           <leader>vr
:LCARSAnimations                         <leader>va
:LCARSRefresh     (re-poll telemetry)    <leader>vt
:LCARSReload      (reload modules)       <leader>vR
```

`<leader>v` ("Voyager") is used because LazyVim already binds `<leader>uL`,
`<leader>uA`, `<leader>uS` and `<leader>uD`.

## Architecture

```
colors/lcars.lua           colorscheme entry point -> lcars.theme
lua/lcars/
  plugins/init.lua         lazy.nvim specs (import = "lcars.plugins"): setup(), Snacks
                           dashboard/notifier dispatchers, which-key group
  health.lua               :checkhealth lcars
  init.lua                 public API: setup/enable/disable/toggle/red_alert/animations/
                           status/center/refresh/reload; persistence (stdpath("state")/lcars.json)
  state.lua                single runtime state table every component reads
  palette.lua              all colours, semantic roles, mode labels, filetype labels
  highlights.lua           highlight groups (editor, treesitter, LSP, diagnostics, plugins,
                           Lcars* UI groups); alert() = Red Alert overrides
  theme.lua                applies highlights; apply_alert(); re-applies Lcars* groups when
                           another colorscheme is loaded while LCARS is on
  borders.lua              asymmetric LCARS border sets (normal/search/warning/error/debug/ai)
  statusline.lua           the control strip; width-aware (shorten then drop by priority)
  winbar.lua               SYS id › PROJECT › dir › file › symbol (trouble.nvim symbols)
  animations.lua           the one repeating timer; heartbeat, spinners, data readout,
                           focus pause/resume
  dashboard.lua            Snacks dashboard sections, boot sequence, data cascade
  notifications.lua        Snacks notifier style + event() for contextual system messages
  picker.lua               Snacks picker prompt/layouts (LCARS DATABASE QUERY)
  bufferline.lua           bufferline.nvim restyle / restore
  system.lua               session ids, uptime, stardate, :LCARSStatus window
  center.lua               :LCARS control center (Snacks picker)
  python.lua               interpreter/venv/version/ruff/formatter (cached per root)
  git.lua                  branch, worktree, M/S/? counts, ahead/behind (throttled async git)
  lsp.lua                  attached clients, progress busy flag, diagnostic counts
  tests.lua                neotest if present, else pytest's own cache (fs-watched)
  dap.lua                  nvim-dap listeners (only when installed)
  ai.lua                   Avante / Copilot state from their APIs (never guessed)
  events.lua               ColorScheme guard, LazyLoad hooks, resize, python-open message
  commands.lua / keymaps.lua
  util.lua                 timers, throttle/debounce, async fs/process helpers
```

Enable = save previous settings → `colorscheme lcars` → one augroup (`lcars`) →
each module's `setup(group)` → single animation timer.
Disable = each module's `teardown()` → delete the augroup → restore colorscheme,
guicursor, fillchars, lualine (`hide{unhide=true}`), bufferline (`LazyVim.opts`),
picker config. Toggling repeatedly creates no duplicate autocmds or timers.

## Configuration (`opts`)

| key | default | meaning |
|---|---|---|
| `enabled` | false | boot into LCARS regardless of persistence |
| `persist_mode` | false | remember on/off across restarts |
| `fallback_colorscheme` | nil | restore target if detection fails |
| `transparent` | true | keep Ghostty's glass background |
| `dim_inactive` | true | muted text in inactive windows |
| `cursor` | true | steady (non-blinking) cursor while on |
| `animations.{enabled,interval,pause_unfocused}` | true, 750, true | the timer |
| `heartbeat` / `data_cascade` / `stardate` | true | decorative readouts |
| `system_messages` | true | contextual notices tied to real events |
| `dashboard` `statusline` `winbar` `notifications` `picker` `diagnostics` `bufferline` | true | components |
| `python` `git` `tests` `dap` `ai` | true | subsystems |
| `python_always` | false | show PYTHON segment in non-Python buffers too |
| `red_alert.{enabled,automatic,threshold}` | true, false, 1 | auto-engage on errors |

## Customising

- Colours: edit `palette.lua` only. `roles` maps subsystems to colours.
- Mode labels/colours and filetype labels: `palette.lua` (`modes`, `filetypes`).
- Statusline segments: `statusline.lua`, one `seg_*` function each; `seg(id, prio,
  parts, short)`; lower prio survives longer in narrow windows (0 is never dropped).
- Dashboard rows and keys: `dashboard.lua` (`status_items`, `key_items`).
- Notification headers per level: `notifications.lua` (`HEADERS`, `BORDERS`).
- Control-center entries: `center.lua`.
- Borders: `borders.lua`.

## Dashboard elbows

The launch screen's elbows are real quarter-circles.  In terminals that implement the
kitty graphics protocol with unicode placeholders (Ghostty, kitty) the corners
are the anti-aliased PNGs in `assets/`, transmitted once per session by
`lua/lcars/graphics.lua` and placed inside ordinary buffer cells, so they scroll and
redraw like text.  Everywhere else (WezTerm lacks placeholder support, tmux/screen need passthrough, or with
`vim.g.lcars_graphics = false`) the corners fall back to block glyphs chosen by
measuring real glyph coverage against a circle.  Red Alert swaps the corner colours.

## Notes

- `FilipJaskovic/lcars.nvim` was evaluated and not used: it occupies the same `lua/lcars`
  module namespace and its palette is a TNG/VS Code port; this theme is self-contained.
- Tests are never executed by LCARS. Results come from neotest (if installed) or
  pytest's `.pytest_cache` written by your own runs; a file watcher makes them live.
- Developed against Ghostty with JetBrainsMono Nerd Font; any truecolor terminal works.
