-- Highlight definitions for the LCARS colorscheme. Pure data: returns a table
-- of group -> attrs. Applied by lcars.theme.
local P = require("lcars.palette")

local M = {}

---@param opts {transparent?: boolean, dim_inactive?: boolean}
function M.get(opts)
  opts = opts or {}
  local c = P.colors
  local bg = opts.transparent and "NONE" or c.black
  local float_bg = opts.transparent and "NONE" or c.black

  local g = {}

  -- Editor chrome ----------------------------------------------------------
  g.Normal = { fg = c.text, bg = bg }
  g.NormalNC = { fg = opts.dim_inactive and c.text_dim or c.text, bg = bg }
  g.NormalFloat = { fg = c.text, bg = float_bg }
  g.FloatBorder = { fg = c.orange, bg = float_bg }
  g.FloatTitle = { fg = c.black, bg = c.orange, bold = true }
  g.FloatFooter = { fg = c.gray, bg = float_bg }
  g.WinSeparator = { fg = c.gray2, bg = bg }
  g.VertSplit = { link = "WinSeparator" }
  g.SignColumn = { bg = bg }
  g.LineNr = { fg = c.gray3 }
  g.LineNrAbove = { fg = c.gray3 }
  g.LineNrBelow = { fg = c.gray3 }
  g.CursorLineNr = { fg = c.orange, bold = true }
  g.CursorLine = { bg = c.gray1 }
  g.CursorColumn = { bg = c.gray1 }
  g.ColorColumn = { bg = c.gray1 }
  g.Cursor = { fg = c.black, bg = c.amber }
  g.lCursor = { link = "Cursor" }
  g.CursorIM = { link = "Cursor" }
  g.TermCursor = { fg = c.black, bg = c.amber }
  g.Visual = { bg = c.gray2 }
  g.VisualNOS = { bg = c.gray2 }
  g.Search = { fg = c.black, bg = c.amber }
  g.IncSearch = { fg = c.black, bg = c.orange }
  g.CurSearch = { fg = c.black, bg = c.orange }
  g.Substitute = { fg = c.black, bg = c.salmon }
  g.MatchParen = { fg = c.amber, bold = true, underline = true }
  g.Pmenu = { fg = c.text, bg = c.panel }
  g.PmenuSel = { fg = c.black, bg = c.peach, bold = true }
  g.PmenuKind = { fg = c.lilac, bg = c.panel }
  g.PmenuKindSel = { fg = c.black, bg = c.peach }
  g.PmenuExtra = { fg = c.gray, bg = c.panel }
  g.PmenuExtraSel = { fg = c.black, bg = c.peach }
  g.PmenuSbar = { bg = c.gray1 }
  g.PmenuThumb = { bg = c.orange }
  g.PmenuMatch = { fg = c.orange, bold = true }
  g.PmenuMatchSel = { fg = c.black, bg = c.peach, bold = true }
  g.StatusLine = { fg = c.text, bg = "NONE" }
  g.StatusLineNC = { fg = c.gray, bg = "NONE" }
  g.WinBar = { fg = c.text_dim, bg = "NONE" }
  g.WinBarNC = { fg = c.gray, bg = "NONE" }
  g.TabLine = { fg = c.gray, bg = "NONE" }
  g.TabLineFill = { bg = "NONE" }
  g.TabLineSel = { fg = c.black, bg = c.orange, bold = true }
  g.Folded = { fg = c.lavender, bg = c.gray1 }
  g.FoldColumn = { fg = c.gray3, bg = bg }
  g.Title = { fg = c.orange, bold = true }
  g.NonText = { fg = c.gray2 }
  g.Whitespace = { fg = c.gray1 }
  g.SpecialKey = { fg = c.violet }
  g.EndOfBuffer = { fg = bg == "NONE" and c.black or bg }
  g.Directory = { fg = c.lilac }
  g.Conceal = { fg = c.gray }
  g.Error = { fg = c.red_bright }
  g.ErrorMsg = { fg = c.red_bright, bold = true }
  g.WarningMsg = { fg = c.orange }
  g.MoreMsg = { fg = c.green }
  g.ModeMsg = { fg = c.amber, bold = true }
  g.Question = { fg = c.ice }
  g.QuickFixLine = { bg = c.gray1, bold = true }
  g.WildMenu = { fg = c.black, bg = c.amber }
  g.SpellBad = { undercurl = true, sp = c.red }
  g.SpellCap = { undercurl = true, sp = c.blue }
  g.SpellLocal = { undercurl = true, sp = c.green }
  g.SpellRare = { undercurl = true, sp = c.violet }
  g.DiffAdd = { bg = "#0b2a20" }
  g.DiffChange = { bg = "#1a1a2e" }
  g.DiffDelete = { bg = "#2a0f0f", fg = c.red }
  g.DiffText = { bg = "#2a2a4e" }
  g.Added = { fg = c.green }
  g.Changed = { fg = c.amber }
  g.Removed = { fg = c.red }
  g.healthSuccess = { fg = c.black, bg = c.green }
  g.healthWarning = { fg = c.black, bg = c.amber }
  g.healthError = { fg = c.black, bg = c.red }

  -- Syntax (legacy groups) -------------------------------------------------
  -- Readability rule: code body is near-white; only a handful of LCARS
  -- colours inside source. Theatrics stay in the chrome.
  g.Comment = { fg = c.gray, italic = true }
  g.Constant = { fg = c.ice }
  g.String = { fg = c.almond }
  g.Character = { fg = c.almond }
  g.Number = { fg = c.ice }
  g.Boolean = { fg = c.ice, bold = true }
  g.Float = { fg = c.ice }
  g.Identifier = { fg = c.text }
  g.Function = { fg = c.amber }
  g.Statement = { fg = c.orange }
  g.Conditional = { fg = c.orange }
  g.Repeat = { fg = c.orange }
  g.Label = { fg = c.orange }
  g.Operator = { fg = c.muted }
  g.Keyword = { fg = c.orange }
  g.Exception = { fg = c.salmon }
  g.PreProc = { fg = c.lavender }
  g.Include = { fg = c.lavender }
  g.Define = { fg = c.lavender }
  g.Macro = { fg = c.lavender }
  g.PreCondit = { fg = c.lavender }
  g.Type = { fg = c.lilac }
  g.StorageClass = { fg = c.lilac }
  g.Structure = { fg = c.lilac }
  g.Typedef = { fg = c.lilac }
  g.Special = { fg = c.peach }
  g.SpecialChar = { fg = c.salmon }
  g.Tag = { fg = c.orange }
  g.Delimiter = { fg = c.muted }
  g.SpecialComment = { fg = c.muted, italic = true }
  g.Debug = { fg = c.salmon }
  g.Underlined = { underline = true }
  g.Bold = { bold = true }
  g.Italic = { italic = true }
  g.Todo = { fg = c.black, bg = c.amber, bold = true }

  -- Treesitter ------------------------------------------------------------
  g["@variable"] = { fg = c.text }
  g["@variable.builtin"] = { fg = c.violet, italic = true }
  g["@variable.parameter"] = { fg = c.lavender, italic = true }
  g["@variable.parameter.builtin"] = { fg = c.lavender, italic = true }
  g["@variable.member"] = { fg = c.sky }
  g["@constant"] = { fg = c.ice }
  g["@constant.builtin"] = { fg = c.ice, bold = true }
  g["@constant.macro"] = { fg = c.ice }
  g["@module"] = { fg = c.lavender }
  g["@module.builtin"] = { fg = c.lavender }
  g["@label"] = { fg = c.orange }
  g["@string"] = { fg = c.almond }
  g["@string.documentation"] = { fg = c.muted, italic = true }
  g["@string.regexp"] = { fg = c.salmon }
  g["@string.escape"] = { fg = c.salmon, bold = true }
  g["@string.special"] = { fg = c.salmon }
  g["@string.special.path"] = { fg = c.almond, underline = true }
  g["@string.special.url"] = { fg = c.ice, underline = true }
  g["@character"] = { fg = c.almond }
  g["@character.special"] = { fg = c.salmon }
  g["@boolean"] = { fg = c.ice, bold = true }
  g["@number"] = { fg = c.ice }
  g["@number.float"] = { fg = c.ice }
  g["@type"] = { fg = c.lilac }
  g["@type.builtin"] = { fg = c.lilac }
  g["@type.definition"] = { fg = c.lilac }
  g["@attribute"] = { fg = c.gold }
  g["@attribute.builtin"] = { fg = c.gold }
  g["@property"] = { fg = c.sky }
  g["@function"] = { fg = c.amber }
  g["@function.builtin"] = { fg = c.gold }
  g["@function.call"] = { fg = c.amber }
  g["@function.macro"] = { fg = c.gold }
  g["@function.method"] = { fg = c.amber }
  g["@function.method.call"] = { fg = c.amber }
  g["@constructor"] = { fg = c.lilac }
  g["@operator"] = { fg = c.muted }
  g["@keyword"] = { fg = c.orange }
  g["@keyword.coroutine"] = { fg = c.orange }
  g["@keyword.function"] = { fg = c.orange }
  g["@keyword.operator"] = { fg = c.orange }
  g["@keyword.import"] = { fg = c.lavender }
  g["@keyword.type"] = { fg = c.orange }
  g["@keyword.modifier"] = { fg = c.orange }
  g["@keyword.repeat"] = { fg = c.orange }
  g["@keyword.return"] = { fg = c.salmon, bold = true }
  g["@keyword.debug"] = { fg = c.salmon }
  g["@keyword.exception"] = { fg = c.salmon }
  g["@keyword.conditional"] = { fg = c.orange }
  g["@keyword.conditional.ternary"] = { fg = c.orange }
  g["@keyword.directive"] = { fg = c.lavender }
  g["@keyword.directive.define"] = { fg = c.lavender }
  g["@punctuation.delimiter"] = { fg = c.muted }
  g["@punctuation.bracket"] = { fg = c.muted }
  g["@punctuation.special"] = { fg = c.salmon }
  g["@comment"] = { fg = c.gray, italic = true }
  g["@comment.documentation"] = { fg = c.muted, italic = true }
  g["@comment.error"] = { fg = c.black, bg = c.red, bold = true }
  g["@comment.warning"] = { fg = c.black, bg = c.amber, bold = true }
  g["@comment.todo"] = { fg = c.black, bg = c.amber, bold = true }
  g["@comment.note"] = { fg = c.black, bg = c.ice, bold = true }
  g["@markup.strong"] = { bold = true }
  g["@markup.italic"] = { italic = true }
  g["@markup.strikethrough"] = { strikethrough = true }
  g["@markup.underline"] = { underline = true }
  g["@markup.heading"] = { fg = c.orange, bold = true }
  g["@markup.heading.1"] = { fg = c.orange, bold = true }
  g["@markup.heading.2"] = { fg = c.amber, bold = true }
  g["@markup.heading.3"] = { fg = c.peach, bold = true }
  g["@markup.heading.4"] = { fg = c.lilac, bold = true }
  g["@markup.heading.5"] = { fg = c.lavender, bold = true }
  g["@markup.heading.6"] = { fg = c.sky, bold = true }
  g["@markup.quote"] = { fg = c.muted, italic = true }
  g["@markup.math"] = { fg = c.ice }
  g["@markup.link"] = { fg = c.ice }
  g["@markup.link.label"] = { fg = c.lavender }
  g["@markup.link.url"] = { fg = c.ice, underline = true }
  g["@markup.raw"] = { fg = c.almond }
  g["@markup.raw.block"] = { fg = c.text_dim }
  g["@markup.list"] = { fg = c.orange }
  g["@markup.list.checked"] = { fg = c.green }
  g["@markup.list.unchecked"] = { fg = c.gray }
  g["@diff.plus"] = { fg = c.green }
  g["@diff.minus"] = { fg = c.red }
  g["@diff.delta"] = { fg = c.amber }
  g["@tag"] = { fg = c.orange }
  g["@tag.builtin"] = { fg = c.orange }
  g["@tag.attribute"] = { fg = c.lavender }
  g["@tag.delimiter"] = { fg = c.muted }
  -- Python specifics
  g["@variable.builtin.python"] = { fg = c.violet, italic = true } -- self, cls
  g["@type.builtin.python"] = { fg = c.lilac }
  g["@function.builtin.python"] = { fg = c.gold }
  g["@attribute.python"] = { fg = c.gold } -- decorators
  g["@keyword.import.python"] = { fg = c.lavender }
  g["@string.documentation.python"] = { fg = c.muted, italic = true }
  g["@constant.builtin.python"] = { fg = c.ice, bold = true } -- None/True/False
  -- YAML/JSON keys
  g["@property.yaml"] = { fg = c.peach }
  g["@property.json"] = { fg = c.peach }
  g["@label.json"] = { fg = c.peach }
  g["@string.yaml"] = { fg = c.text }
  -- SQL
  g["@keyword.sql"] = { fg = c.orange, bold = true }

  -- LSP semantic tokens ---------------------------------------------------
  g["@lsp.type.class"] = { link = "@type" }
  g["@lsp.type.decorator"] = { link = "@attribute" }
  g["@lsp.type.enum"] = { link = "@type" }
  g["@lsp.type.enumMember"] = { link = "@constant" }
  g["@lsp.type.function"] = { link = "@function" }
  g["@lsp.type.interface"] = { link = "@type" }
  g["@lsp.type.macro"] = { link = "@function.macro" }
  g["@lsp.type.method"] = { link = "@function.method" }
  g["@lsp.type.namespace"] = { link = "@module" }
  g["@lsp.type.parameter"] = { link = "@variable.parameter" }
  g["@lsp.type.property"] = { link = "@property" }
  g["@lsp.type.struct"] = { link = "@type" }
  g["@lsp.type.type"] = { link = "@type" }
  g["@lsp.type.typeParameter"] = { fg = c.lavender }
  g["@lsp.type.variable"] = {} -- let treesitter decide
  g["@lsp.type.selfParameter"] = { link = "@variable.builtin" }
  g["@lsp.type.clsParameter"] = { link = "@variable.builtin" }
  g["@lsp.type.builtinConstant"] = { link = "@constant.builtin" }
  g["@lsp.type.magicFunction"] = { link = "@function.builtin" }
  g["@lsp.typemod.variable.readonly"] = { fg = c.ice }
  g["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" }
  g["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" }
  g["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" }
  g["@lsp.mod.deprecated"] = { strikethrough = true }
  g.LspReferenceText = { bg = c.gray1 }
  g.LspReferenceRead = { bg = c.gray1 }
  g.LspReferenceWrite = { bg = c.gray2 }
  g.LspInlayHint = { fg = c.gray3, italic = true }
  g.LspCodeLens = { fg = c.gray, italic = true }
  g.LspSignatureActiveParameter = { fg = c.amber, bold = true }

  -- Diagnostics (LCARS alert colours) --------------------------------------
  g.DiagnosticError = { fg = c.red_bright }
  g.DiagnosticWarn = { fg = c.orange }
  g.DiagnosticInfo = { fg = c.ice }
  g.DiagnosticHint = { fg = c.lavender }
  g.DiagnosticOk = { fg = c.green }
  g.DiagnosticVirtualTextError = { fg = c.red, bg = "#1c0a0a" }
  g.DiagnosticVirtualTextWarn = { fg = c.orange, bg = "#1c1408" }
  g.DiagnosticVirtualTextInfo = { fg = c.ice, bg = "#0a141c" }
  g.DiagnosticVirtualTextHint = { fg = c.lavender, bg = "#140f1c" }
  g.DiagnosticUnderlineError = { undercurl = true, sp = c.red_bright }
  g.DiagnosticUnderlineWarn = { undercurl = true, sp = c.orange }
  g.DiagnosticUnderlineInfo = { undercurl = true, sp = c.ice }
  g.DiagnosticUnderlineHint = { undercurl = true, sp = c.lavender }
  g.DiagnosticSignError = { fg = c.red_bright }
  g.DiagnosticSignWarn = { fg = c.orange }
  g.DiagnosticSignInfo = { fg = c.ice }
  g.DiagnosticSignHint = { fg = c.lavender }
  g.DiagnosticFloatingError = { fg = c.red_bright }
  g.DiagnosticFloatingWarn = { fg = c.orange }
  g.DiagnosticFloatingInfo = { fg = c.ice }
  g.DiagnosticFloatingHint = { fg = c.lavender }
  g.DiagnosticUnnecessary = { fg = c.gray, undercurl = false }
  g.DiagnosticDeprecated = { strikethrough = true, sp = c.gray }

  -- Git -------------------------------------------------------------------
  g.GitSignsAdd = { fg = c.green }
  g.GitSignsChange = { fg = c.amber }
  g.GitSignsDelete = { fg = c.red }
  g.GitSignsAddNr = { fg = c.green }
  g.GitSignsChangeNr = { fg = c.amber }
  g.GitSignsDeleteNr = { fg = c.red }
  g.GitSignsCurrentLineBlame = { fg = c.gray3, italic = true }
  g.gitcommitSummary = { fg = c.text }
  g.gitcommitOverflow = { fg = c.red }

  -- Plugins: Snacks -------------------------------------------------------
  g.SnacksNormal = { fg = c.text, bg = float_bg }
  g.SnacksBackdrop = { bg = c.black }
  g.SnacksDashboardNormal = { fg = c.text, bg = bg }
  g.SnacksDashboardHeader = { fg = c.orange }
  g.SnacksDashboardTitle = { fg = c.orange, bold = true }
  g.SnacksDashboardDesc = { fg = c.text_dim }
  g.SnacksDashboardKey = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksDashboardIcon = { fg = c.orange }
  g.SnacksDashboardFooter = { fg = c.gray }
  g.SnacksDashboardSpecial = { fg = c.lilac }
  g.SnacksDashboardDir = { fg = c.gray }
  g.SnacksDashboardFile = { fg = c.peach }
  g.SnacksDashboardTerminal = { fg = c.orange }
  g.SnacksNotifierInfo = { fg = c.text, bg = float_bg }
  g.SnacksNotifierWarn = { fg = c.text, bg = float_bg }
  g.SnacksNotifierError = { fg = c.text, bg = float_bg }
  g.SnacksNotifierDebug = { fg = c.text_dim, bg = float_bg }
  g.SnacksNotifierTrace = { fg = c.text_dim, bg = float_bg }
  g.SnacksNotifierBorderInfo = { fg = c.orange, bg = float_bg }
  g.SnacksNotifierBorderWarn = { fg = c.amber, bg = float_bg }
  g.SnacksNotifierBorderError = { fg = c.red_bright, bg = float_bg }
  g.SnacksNotifierBorderDebug = { fg = c.violet, bg = float_bg }
  g.SnacksNotifierBorderTrace = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierTitleInfo = { fg = c.black, bg = c.orange, bold = true }
  g.SnacksNotifierTitleWarn = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksNotifierTitleError = { fg = c.black, bg = c.red_bright, bold = true }
  g.SnacksNotifierTitleDebug = { fg = c.black, bg = c.violet, bold = true }
  g.SnacksNotifierTitleTrace = { fg = c.black, bg = c.gray, bold = true }
  g.SnacksNotifierIconInfo = { fg = c.orange }
  g.SnacksNotifierIconWarn = { fg = c.amber }
  g.SnacksNotifierIconError = { fg = c.red_bright }
  g.SnacksNotifierIconDebug = { fg = c.violet }
  g.SnacksNotifierIconTrace = { fg = c.gray }
  g.SnacksNotifierFooterInfo = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierFooterWarn = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierFooterError = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierFooterDebug = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierFooterTrace = { fg = c.gray, bg = float_bg }
  g.SnacksNotifierHistory = { fg = c.text, bg = float_bg }
  g.SnacksNotifierHistoryTitle = { fg = c.orange, bold = true }
  g.SnacksNotifierHistoryDateTime = { fg = c.gray }
  g.SnacksPicker = { fg = c.text, bg = float_bg }
  g.SnacksPickerBorder = { fg = c.orange, bg = float_bg }
  g.SnacksPickerTitle = { fg = c.black, bg = c.orange, bold = true }
  g.SnacksPickerFooter = { fg = c.gray, bg = float_bg }
  g.SnacksPickerInput = { fg = c.text, bg = float_bg }
  g.SnacksPickerInputBorder = { fg = c.amber, bg = float_bg }
  g.SnacksPickerInputTitle = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksPickerInputSearch = { fg = c.amber, italic = true }
  g.SnacksPickerPrompt = { fg = c.orange, bold = true }
  g.SnacksPickerList = { fg = c.text, bg = float_bg }
  g.SnacksPickerListBorder = { fg = c.orange, bg = float_bg }
  g.SnacksPickerListTitle = { fg = c.black, bg = c.lilac, bold = true }
  g.SnacksPickerListCursorLine = { bg = c.gray1, bold = true }
  g.SnacksPickerPreview = { fg = c.text, bg = float_bg }
  g.SnacksPickerPreviewBorder = { fg = c.blue_muted, bg = float_bg }
  g.SnacksPickerPreviewTitle = { fg = c.black, bg = c.sky, bold = true }
  g.SnacksPickerPreviewCursorLine = { bg = c.gray1 }
  g.SnacksPickerBox = { fg = c.text, bg = float_bg }
  g.SnacksPickerBoxBorder = { fg = c.orange, bg = float_bg }
  g.SnacksPickerBoxTitle = { fg = c.black, bg = c.orange, bold = true }
  g.SnacksPickerMatch = { fg = c.orange, bold = true }
  g.SnacksPickerDir = { fg = c.gray }
  g.SnacksPickerFile = { fg = c.text }
  g.SnacksPickerDirectory = { fg = c.lilac }
  g.SnacksPickerPathHidden = { fg = c.gray3 }
  g.SnacksPickerPathIgnored = { fg = c.gray2 }
  g.SnacksPickerIdx = { fg = c.amber, bold = true }
  g.SnacksPickerRow = { fg = c.gray }
  g.SnacksPickerCol = { fg = c.gray }
  g.SnacksPickerDelim = { fg = c.gray3 }
  g.SnacksPickerComment = { fg = c.gray, italic = true }
  g.SnacksPickerSelected = { fg = c.amber, bold = true }
  g.SnacksPickerUnselected = { fg = c.gray3 }
  g.SnacksPickerSpinner = { fg = c.amber }
  g.SnacksPickerTotals = { fg = c.gray }
  g.SnacksPickerToggle = { fg = c.black, bg = c.lilac, bold = true }
  g.SnacksPickerSpecial = { fg = c.lilac }
  g.SnacksPickerLabel = { fg = c.peach }
  g.SnacksPickerCode = { fg = c.almond }
  g.SnacksPickerGitBranch = { fg = c.lilac }
  g.SnacksPickerGitBranchCurrent = { fg = c.orange, bold = true }
  g.SnacksPickerGitCommit = { fg = c.amber }
  g.SnacksPickerGitDate = { fg = c.gray }
  g.SnacksPickerGitStatus = { fg = c.amber }
  g.SnacksPickerGitStatusAdded = { fg = c.green }
  g.SnacksPickerGitStatusModified = { fg = c.amber }
  g.SnacksPickerGitStatusDeleted = { fg = c.red }
  g.SnacksPickerGitStatusUntracked = { fg = c.gray }
  g.SnacksPickerGitStatusStaged = { fg = c.green }
  g.SnacksPickerDiagnosticCode = { fg = c.gray }
  g.SnacksPickerDiagnosticSource = { fg = c.gray, italic = true }
  g.SnacksPickerKeymapLhs = { fg = c.amber, bold = true }
  g.SnacksPickerKeymapMode = { fg = c.lilac }
  g.SnacksPickerKeymapRhs = { fg = c.text_dim }
  g.SnacksPickerBufFlags = { fg = c.gray }
  g.SnacksPickerBufNr = { fg = c.amber }
  g.SnacksPickerIcon = { fg = c.orange }
  g.SnacksPickerPickWin = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksIndent = { fg = c.gray1 }
  g.SnacksIndentScope = { fg = c.orange }
  g.SnacksIndentChunk = { fg = c.orange }
  g.SnacksInputNormal = { fg = c.text, bg = float_bg }
  g.SnacksInputBorder = { fg = c.amber, bg = float_bg }
  g.SnacksInputTitle = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksInputIcon = { fg = c.amber }
  g.SnacksInputPrompt = { fg = c.orange, bold = true }
  g.SnacksTerminal = { fg = c.text, bg = float_bg }
  g.SnacksWinBar = { fg = c.orange, bold = true }
  g.SnacksWinBarNC = { fg = c.gray }
  g.SnacksDim = { fg = c.gray3 }
  g.SnacksScratchKey = { fg = c.black, bg = c.amber, bold = true }
  g.SnacksScratchDesc = { fg = c.text_dim }
  g.SnacksZenIcon = { fg = c.orange }
  g.SnacksProfilerBadge = { fg = c.black, bg = c.amber }

  -- Telescope (used by git-worktree only) ----------------------------------
  g.TelescopeNormal = { fg = c.text, bg = float_bg }
  g.TelescopeBorder = { fg = c.orange, bg = float_bg }
  g.TelescopePromptNormal = { fg = c.text, bg = float_bg }
  g.TelescopePromptBorder = { fg = c.amber, bg = float_bg }
  g.TelescopePromptTitle = { fg = c.black, bg = c.amber, bold = true }
  g.TelescopePromptPrefix = { fg = c.orange, bold = true }
  g.TelescopeResultsTitle = { fg = c.black, bg = c.lilac, bold = true }
  g.TelescopePreviewTitle = { fg = c.black, bg = c.sky, bold = true }
  g.TelescopeSelection = { bg = c.gray1, bold = true }
  g.TelescopeSelectionCaret = { fg = c.orange }
  g.TelescopeMatching = { fg = c.orange, bold = true }
  g.TelescopeTitle = { fg = c.orange, bold = true }

  -- Noice / cmdline -------------------------------------------------------
  g.NoiceCmdline = { fg = c.text, bg = "NONE" }
  g.NoiceCmdlinePopup = { fg = c.text, bg = float_bg }
  g.NoiceCmdlinePopupBorder = { fg = c.orange, bg = float_bg }
  g.NoiceCmdlinePopupTitle = { fg = c.black, bg = c.orange, bold = true }
  g.NoiceCmdlinePopupBorderSearch = { fg = c.amber, bg = float_bg }
  g.NoiceCmdlinePopupTitleSearch = { fg = c.black, bg = c.amber, bold = true }
  g.NoiceCmdlinePopupBorderLua = { fg = c.lilac, bg = float_bg }
  g.NoiceCmdlinePopupTitleLua = { fg = c.black, bg = c.lilac, bold = true }
  g.NoiceCmdlinePopupBorderHelp = { fg = c.sky, bg = float_bg }
  g.NoiceCmdlinePopupTitleHelp = { fg = c.black, bg = c.sky, bold = true }
  g.NoiceCmdlinePopupBorderFilter = { fg = c.violet, bg = float_bg }
  g.NoiceCmdlinePopupBorderInput = { fg = c.amber, bg = float_bg }
  g.NoiceCmdlineIcon = { fg = c.orange, bold = true }
  g.NoiceCmdlineIconSearch = { fg = c.amber }
  g.NoiceCmdlineIconLua = { fg = c.lilac }
  g.NoiceCmdlineIconHelp = { fg = c.sky }
  g.NoiceCmdlineIconFilter = { fg = c.violet }
  g.NoiceCmdlinePrompt = { fg = c.amber }
  g.NoiceConfirm = { fg = c.text, bg = float_bg }
  g.NoiceConfirmBorder = { fg = c.amber, bg = float_bg }
  g.NoicePopup = { fg = c.text, bg = float_bg }
  g.NoicePopupBorder = { fg = c.orange, bg = float_bg }
  g.NoicePopupmenu = { fg = c.text, bg = c.panel }
  g.NoicePopupmenuBorder = { fg = c.orange, bg = c.panel }
  g.NoicePopupmenuSelected = { fg = c.black, bg = c.peach, bold = true }
  g.NoicePopupmenuMatch = { fg = c.orange, bold = true }
  g.NoiceMini = { fg = c.text_dim, bg = "NONE" }
  g.NoiceLspProgressTitle = { fg = c.orange }
  g.NoiceLspProgressClient = { fg = c.lilac, bold = true }
  g.NoiceLspProgressSpinner = { fg = c.amber }
  g.NoiceFormatProgressDone = { fg = c.black, bg = c.orange }
  g.NoiceFormatProgressTodo = { fg = c.gray, bg = c.gray1 }
  g.NoiceVirtualText = { fg = c.amber }
  g.NoiceScrollbar = { bg = c.gray1 }
  g.NoiceScrollbarThumb = { bg = c.orange }

  -- Which-key ------------------------------------------------------------
  g.WhichKey = { fg = c.amber, bold = true }
  g.WhichKeyGroup = { fg = c.orange }
  g.WhichKeyDesc = { fg = c.text_dim }
  g.WhichKeySeparator = { fg = c.gray3 }
  g.WhichKeyIcon = { fg = c.lilac }
  g.WhichKeyIconAzure = { fg = c.ice }
  g.WhichKeyIconBlue = { fg = c.blue }
  g.WhichKeyIconCyan = { fg = c.ice }
  g.WhichKeyIconGreen = { fg = c.green }
  g.WhichKeyIconGrey = { fg = c.gray }
  g.WhichKeyIconOrange = { fg = c.orange }
  g.WhichKeyIconPurple = { fg = c.lilac }
  g.WhichKeyIconRed = { fg = c.red }
  g.WhichKeyIconYellow = { fg = c.amber }
  g.WhichKeyNormal = { fg = c.text, bg = float_bg }
  g.WhichKeyBorder = { fg = c.orange, bg = float_bg }
  g.WhichKeyTitle = { fg = c.black, bg = c.orange, bold = true }
  g.WhichKeyValue = { fg = c.gray }

  -- Blink.cmp --------------------------------------------------------------
  g.BlinkCmpMenu = { fg = c.text, bg = c.panel }
  g.BlinkCmpMenuBorder = { fg = c.orange, bg = c.panel }
  g.BlinkCmpMenuSelection = { fg = c.black, bg = c.peach, bold = true }
  g.BlinkCmpScrollBarThumb = { bg = c.orange }
  g.BlinkCmpScrollBarGutter = { bg = c.gray1 }
  g.BlinkCmpLabel = { fg = c.text }
  g.BlinkCmpLabelDeprecated = { fg = c.gray, strikethrough = true }
  g.BlinkCmpLabelMatch = { fg = c.orange, bold = true }
  g.BlinkCmpLabelDetail = { fg = c.gray }
  g.BlinkCmpLabelDescription = { fg = c.gray }
  g.BlinkCmpKind = { fg = c.lilac }
  g.BlinkCmpKindFunction = { fg = c.amber }
  g.BlinkCmpKindMethod = { fg = c.amber }
  g.BlinkCmpKindClass = { fg = c.lilac }
  g.BlinkCmpKindVariable = { fg = c.text }
  g.BlinkCmpKindKeyword = { fg = c.orange }
  g.BlinkCmpKindSnippet = { fg = c.peach }
  g.BlinkCmpKindModule = { fg = c.lavender }
  g.BlinkCmpKindText = { fg = c.text_dim }
  g.BlinkCmpKindProperty = { fg = c.sky }
  g.BlinkCmpKindField = { fg = c.sky }
  g.BlinkCmpKindConstant = { fg = c.ice }
  g.BlinkCmpSource = { fg = c.gray }
  g.BlinkCmpGhostText = { fg = c.gray3, italic = true }
  g.BlinkCmpDoc = { fg = c.text, bg = c.panel }
  g.BlinkCmpDocBorder = { fg = c.blue_muted, bg = c.panel }
  g.BlinkCmpDocSeparator = { fg = c.gray3, bg = c.panel }
  g.BlinkCmpDocCursorLine = { bg = c.gray1 }
  g.BlinkCmpSignatureHelp = { fg = c.text, bg = c.panel }
  g.BlinkCmpSignatureHelpBorder = { fg = c.amber, bg = c.panel }
  g.BlinkCmpSignatureHelpActiveParameter = { fg = c.amber, bold = true }

  -- Flash ----------------------------------------------------------------
  g.FlashLabel = { fg = c.black, bg = c.orange, bold = true }
  g.FlashMatch = { fg = c.amber }
  g.FlashCurrent = { fg = c.black, bg = c.amber }
  g.FlashBackdrop = { fg = c.gray3 }
  g.FlashPrompt = { fg = c.text, bg = float_bg }
  g.FlashPromptIcon = { fg = c.orange }

  -- Trouble / todo-comments -------------------------------------------------
  g.TroubleNormal = { fg = c.text, bg = bg }
  g.TroubleNormalNC = { fg = c.text_dim, bg = bg }
  g.TroubleIndent = { fg = c.gray2 }
  g.TroubleCount = { fg = c.black, bg = c.amber, bold = true }
  g.TroubleDirectory = { fg = c.lilac }
  g.TroubleFilename = { fg = c.peach }
  g.TroublePos = { fg = c.gray }
  g.TroubleIconDirectory = { fg = c.lilac }
  g.TroublePreview = { bg = c.gray1 }
  g.TodoBgTODO = { fg = c.black, bg = c.amber, bold = true }
  g.TodoFgTODO = { fg = c.amber }
  g.TodoBgFIX = { fg = c.black, bg = c.red, bold = true }
  g.TodoFgFIX = { fg = c.red }
  g.TodoBgWARN = { fg = c.black, bg = c.orange, bold = true }
  g.TodoFgWARN = { fg = c.orange }
  g.TodoBgNOTE = { fg = c.black, bg = c.ice, bold = true }
  g.TodoFgNOTE = { fg = c.ice }
  g.TodoBgHACK = { fg = c.black, bg = c.salmon, bold = true }
  g.TodoFgHACK = { fg = c.salmon }
  g.TodoBgPERF = { fg = c.black, bg = c.lilac, bold = true }
  g.TodoFgPERF = { fg = c.lilac }
  g.TodoBgTEST = { fg = c.black, bg = c.green, bold = true }
  g.TodoFgTEST = { fg = c.green }

  -- Lazy / Mason ----------------------------------------------------------
  g.LazyNormal = { fg = c.text, bg = float_bg }
  g.LazyH1 = { fg = c.black, bg = c.orange, bold = true }
  g.LazyH2 = { fg = c.orange, bold = true }
  g.LazyButton = { fg = c.text_dim, bg = c.gray1 }
  g.LazyButtonActive = { fg = c.black, bg = c.amber, bold = true }
  g.LazySpecial = { fg = c.lilac }
  g.LazyProgressDone = { fg = c.orange }
  g.LazyProgressTodo = { fg = c.gray2 }
  g.LazyReasonPlugin = { fg = c.lilac }
  g.LazyReasonEvent = { fg = c.amber }
  g.LazyReasonCmd = { fg = c.ice }
  g.LazyReasonFt = { fg = c.peach }
  g.LazyReasonKeys = { fg = c.lavender }
  g.LazyReasonStart = { fg = c.green }
  g.LazyReasonSource = { fg = c.sky }
  g.LazyReasonImport = { fg = c.violet }
  g.LazyReasonRequire = { fg = c.salmon }
  g.LazyReasonRuntime = { fg = c.gray }
  g.LazyCommit = { fg = c.gray }
  g.LazyCommitType = { fg = c.amber }
  g.LazyDir = { fg = c.lilac }
  g.LazyUrl = { fg = c.ice }
  g.LazyValue = { fg = c.almond }
  g.LazyProp = { fg = c.gray }
  g.LazyDimmed = { fg = c.gray }
  g.LazyLocal = { fg = c.green }
  g.LazyNoCond = { fg = c.gray3 }
  g.LazyTaskOutput = { fg = c.text_dim }
  g.LazyTaskError = { fg = c.red }
  g.MasonNormal = { fg = c.text, bg = float_bg }
  g.MasonHeader = { fg = c.black, bg = c.orange, bold = true }
  g.MasonHeaderSecondary = { fg = c.black, bg = c.amber, bold = true }
  g.MasonHighlight = { fg = c.amber }
  g.MasonHighlightBlock = { fg = c.black, bg = c.amber }
  g.MasonHighlightBlockBold = { fg = c.black, bg = c.amber, bold = true }
  g.MasonHighlightSecondary = { fg = c.lilac }
  g.MasonHighlightBlockSecondary = { fg = c.black, bg = c.lilac }
  g.MasonHighlightBlockBoldSecondary = { fg = c.black, bg = c.lilac, bold = true }
  g.MasonMuted = { fg = c.gray }
  g.MasonMutedBlock = { fg = c.text, bg = c.gray2 }
  g.MasonMutedBlockBold = { fg = c.text, bg = c.gray2, bold = true }
  g.MasonError = { fg = c.red }
  g.MasonWarning = { fg = c.orange }
  g.MasonHeading = { fg = c.orange, bold = true }

  -- Avante / AI -----------------------------------------------------------
  g.AvanteTitle = { fg = c.black, bg = c.violet, bold = true }
  g.AvanteReversedTitle = { fg = c.violet }
  g.AvanteSubtitle = { fg = c.black, bg = c.lilac, bold = true }
  g.AvanteReversedSubtitle = { fg = c.lilac }
  g.AvanteThirdTitle = { fg = c.black, bg = c.lavender, bold = true }
  g.AvanteReversedThirdTitle = { fg = c.lavender }
  g.AvanteSidebarWinSeparator = { fg = c.violet, bg = bg }
  g.AvanteSidebarWinHorizontalSeparator = { fg = c.gray2, bg = bg }
  g.AvanteSidebarNormal = { fg = c.text, bg = bg }
  g.AvanteConflictCurrent = { bg = "#2a1a10" }
  g.AvanteConflictIncoming = { bg = "#101a2a" }
  g.AvanteConflictCurrentLabel = { fg = c.black, bg = c.orange, bold = true }
  g.AvanteConflictIncomingLabel = { fg = c.black, bg = c.ice, bold = true }
  g.AvanteToBeDeleted = { bg = "#2a0f0f", strikethrough = true }
  g.AvanteToBeDeletedWOStrikethrough = { bg = "#2a0f0f" }
  g.AvanteSuggestion = { fg = c.gray3, italic = true }
  g.AvanteAnnotation = { fg = c.gray, italic = true }
  g.AvantePopupHint = { fg = c.gray }
  g.AvanteInlineHint = { fg = c.violet, italic = true }
  g.AvantePromptInput = { fg = c.text, bg = float_bg }
  g.AvantePromptInputBorder = { fg = c.violet, bg = float_bg }
  g.AvanteButtonDefault = { fg = c.text, bg = c.gray2 }
  g.AvanteButtonDefaultHover = { fg = c.black, bg = c.amber }
  g.AvanteButtonPrimary = { fg = c.black, bg = c.violet, bold = true }
  g.AvanteButtonPrimaryHover = { fg = c.black, bg = c.lilac, bold = true }
  g.AvanteButtonDanger = { fg = c.black, bg = c.red }
  g.AvanteButtonDangerHover = { fg = c.black, bg = c.red_bright }
  g.AvanteStateSpinnerGenerating = { fg = c.black, bg = c.violet, bold = true }
  g.AvanteStateSpinnerToolCalling = { fg = c.black, bg = c.lilac, bold = true }
  g.AvanteStateSpinnerFailed = { fg = c.black, bg = c.red, bold = true }
  g.AvanteStateSpinnerSucceeded = { fg = c.black, bg = c.green, bold = true }
  g.AvanteStateSpinnerSearching = { fg = c.black, bg = c.sky, bold = true }
  g.AvanteStateSpinnerThinking = { fg = c.black, bg = c.lavender, bold = true }
  g.AvanteStateSpinnerCompacting = { fg = c.black, bg = c.gray, bold = true }
  g.AvanteTaskCompleted = { fg = c.green }
  g.AvanteTaskFailed = { fg = c.red }
  g.AvanteTaskRunning = { fg = c.amber }
  g.AvanteThinking = { fg = c.lavender, italic = true }
  g.AvanteConfirmTitle = { fg = c.black, bg = c.amber, bold = true }
  g.CopilotSuggestion = { fg = c.gray3, italic = true }
  g.CopilotAnnotation = { fg = c.gray, italic = true }

  -- DAP / Neotest -----------------------------------------------------------
  g.DapBreakpoint = { fg = c.red_bright }
  g.DapBreakpointCondition = { fg = c.amber }
  g.DapBreakpointRejected = { fg = c.gray }
  g.DapLogPoint = { fg = c.ice }
  g.DapStopped = { fg = c.green }
  g.DapStoppedLine = { bg = "#1c1a08" }
  g.DapUIScope = { fg = c.orange }
  g.DapUIType = { fg = c.lilac }
  g.DapUIValue = { fg = c.text }
  g.DapUIModifiedValue = { fg = c.amber, bold = true }
  g.DapUIDecoration = { fg = c.orange }
  g.DapUIThread = { fg = c.green }
  g.DapUIStoppedThread = { fg = c.amber }
  g.DapUISource = { fg = c.lilac }
  g.DapUILineNumber = { fg = c.ice }
  g.DapUIFloatBorder = { fg = c.salmon }
  g.DapUIWatchesEmpty = { fg = c.gray }
  g.DapUIWatchesValue = { fg = c.green }
  g.DapUIWatchesError = { fg = c.red }
  g.DapUIBreakpointsPath = { fg = c.lilac }
  g.DapUIBreakpointsInfo = { fg = c.green }
  g.DapUIBreakpointsCurrentLine = { fg = c.amber, bold = true }
  g.DapUIPlayPause = { fg = c.green }
  g.DapUIRestart = { fg = c.green }
  g.DapUIStop = { fg = c.red }
  g.DapUIStepOver = { fg = c.ice }
  g.DapUIStepInto = { fg = c.ice }
  g.DapUIStepBack = { fg = c.ice }
  g.DapUIStepOut = { fg = c.ice }
  g.NeotestPassed = { fg = c.green }
  g.NeotestFailed = { fg = c.red_bright }
  g.NeotestRunning = { fg = c.amber }
  g.NeotestSkipped = { fg = c.gray }
  g.NeotestNamespace = { fg = c.lilac }
  g.NeotestFile = { fg = c.peach }
  g.NeotestDir = { fg = c.lilac }
  g.NeotestAdapterName = { fg = c.orange, bold = true }
  g.NeotestIndent = { fg = c.gray2 }
  g.NeotestExpandMarker = { fg = c.gray }
  g.NeotestMarked = { fg = c.amber, bold = true }
  g.NeotestTarget = { fg = c.orange }
  g.NeotestWinSelect = { fg = c.orange, bold = true }
  g.NeotestFocused = { bold = true }
  g.NeotestTest = { fg = c.text }
  g.NeotestUnknown = { fg = c.gray }

  -- Misc plugins ------------------------------------------------------------
  g.IlluminatedWordText = { bg = c.gray1 }
  g.IlluminatedWordRead = { bg = c.gray1 }
  g.IlluminatedWordWrite = { bg = c.gray2 }
  g.RenderMarkdownH1Bg = { fg = c.orange, bg = "#1c1408", bold = true }
  g.RenderMarkdownH2Bg = { fg = c.amber, bg = "#1a160a", bold = true }
  g.RenderMarkdownH3Bg = { fg = c.peach, bg = c.gray1, bold = true }
  g.RenderMarkdownH4Bg = { fg = c.lilac, bg = c.gray1, bold = true }
  g.RenderMarkdownH5Bg = { fg = c.lavender, bg = c.gray1, bold = true }
  g.RenderMarkdownH6Bg = { fg = c.sky, bg = c.gray1, bold = true }
  g.RenderMarkdownCode = { bg = c.panel }
  g.RenderMarkdownCodeInline = { fg = c.almond, bg = c.panel }
  g.RenderMarkdownBullet = { fg = c.orange }
  g.RenderMarkdownQuote = { fg = c.muted, italic = true }
  g.RenderMarkdownDash = { fg = c.gray2 }
  g.RenderMarkdownLink = { fg = c.ice }
  g.RenderMarkdownTableHead = { fg = c.orange }
  g.RenderMarkdownTableRow = { fg = c.gray }
  g.RenderMarkdownChecked = { fg = c.green }
  g.RenderMarkdownUnchecked = { fg = c.gray }
  g.MiniIconsAzure = { fg = c.ice }
  g.MiniIconsBlue = { fg = c.blue }
  g.MiniIconsCyan = { fg = c.ice }
  g.MiniIconsGreen = { fg = c.green }
  g.MiniIconsGrey = { fg = c.gray }
  g.MiniIconsOrange = { fg = c.orange }
  g.MiniIconsPurple = { fg = c.lilac }
  g.MiniIconsRed = { fg = c.red }
  g.MiniIconsYellow = { fg = c.amber }
  g.GrugFarResultsMatch = { fg = c.orange, bold = true }
  g.GrugFarHelpHeader = { fg = c.orange }
  g.GrugFarInputLabel = { fg = c.amber, bold = true }
  g.GrugFarResultsPath = { fg = c.lilac }
  g.GrugFarResultsLineNo = { fg = c.gray }
  g.GrugFarResultsLineColumn = { fg = c.gray }
  g.NeoTreeNormal = { fg = c.text, bg = bg }
  g.NeoTreeNormalNC = { fg = c.text_dim, bg = bg }
  g.NeoTreeDirectoryName = { fg = c.lilac }
  g.NeoTreeDirectoryIcon = { fg = c.orange }
  g.NeoTreeRootName = { fg = c.orange, bold = true }
  g.NeoTreeGitModified = { fg = c.amber }
  g.NeoTreeGitAdded = { fg = c.green }
  g.NeoTreeGitDeleted = { fg = c.red }
  g.NeoTreeGitUntracked = { fg = c.gray }
  g.NeoTreeIndentMarker = { fg = c.gray2 }
  g.NeoTreeWinSeparator = { fg = c.gray2, bg = bg }
  g.DressingInputNormal = { fg = c.text, bg = float_bg }
  g.DressingInputBorder = { fg = c.amber, bg = float_bg }
  g.DressingInputTitle = { fg = c.black, bg = c.amber, bold = true }
  g.VimwikiHeader1 = { fg = c.orange, bold = true }
  g.VimwikiHeader2 = { fg = c.amber, bold = true }
  g.VimwikiHeader3 = { fg = c.peach, bold = true }
  g.VimwikiLink = { fg = c.ice, underline = true }
  g.VimwikiBold = { bold = true }
  g.VimwikiItalic = { italic = true }
  g.VimwikiCode = { fg = c.almond, bg = c.panel }

  -- Terminal palette -------------------------------------------------------
  g.terminal = {
    c.black,
    c.tomato,
    c.green,
    c.amber,
    c.blue,
    c.lilac,
    c.ice,
    c.text,
    c.gray,
    c.red_bright,
    c.green_dark,
    c.gold,
    c.sky,
    c.lavender,
    c.ice,
    c.white,
  }

  -- LCARS-specific UI groups ----------------------------------------------
  -- Block: solid colour bar with black text (LCARS button/panel).
  -- Cap: the rounded end of a bar (fg colour on transparent).
  -- Read: dark readout block with coloured text (LCARS data display).
  -- Text: plain coloured text on transparent.
  for name, hex in pairs(c) do
    local cap = name:sub(1, 1):upper() .. name:sub(2)
    g["LcarsBlock" .. cap] = { fg = c.black, bg = hex, bold = true }
    g["LcarsCap" .. cap] = { fg = hex, bg = "NONE" }
    g["LcarsRead" .. cap] = { fg = hex, bg = c.panel }
    g["LcarsReadCap" .. cap] = { fg = c.panel, bg = "NONE" }
    g["LcarsText" .. cap] = { fg = hex, bg = "NONE" }
  end
  g.LcarsRail = { fg = c.gray2, bg = "NONE" }
  g.LcarsRailAlert = { fg = c.red, bg = "NONE" }
  g.LcarsGap = { fg = c.black, bg = "NONE" }
  g.LcarsReadText = { fg = c.text_dim, bg = c.panel }
  g.LcarsReadDim = { fg = c.gray, bg = c.panel }
  g.LcarsReadBold = { fg = c.text, bg = c.panel, bold = true }
  g.LcarsWinbarId = { fg = c.black, bg = c.lilac, bold = true }
  g.LcarsWinbarIdCap = { fg = c.lilac, bg = "NONE" }
  g.LcarsWinbarIdNC = { fg = c.black, bg = c.gray3, bold = true }
  g.LcarsWinbarIdCapNC = { fg = c.gray3, bg = "NONE" }
  g.LcarsWinbarProject = { fg = c.peach, bg = "NONE", bold = true }
  g.LcarsWinbarDir = { fg = c.gray, bg = "NONE" }
  g.LcarsWinbarFile = { fg = c.text, bg = "NONE", bold = true }
  g.LcarsWinbarFileMod = { fg = c.amber, bg = "NONE", bold = true }
  g.LcarsWinbarSep = { fg = c.orange, bg = "NONE" }
  g.LcarsWinbarSymbol = { fg = c.lavender, bg = "NONE" }
  g.LcarsWinbarLabel = { fg = c.gray, bg = "NONE" }
  g.LcarsWinbarNC = { fg = c.gray3, bg = "NONE" }
  g.LcarsDashTitle = { fg = c.black, bg = c.orange, bold = true }
  g.LcarsDashSubtitle = { fg = c.orange, bold = true }
  g.LcarsDashBar = { fg = c.orange }
  g.LcarsDashBar2 = { fg = c.lilac }
  g.LcarsDashBar3 = { fg = c.peach }
  g.LcarsDashBar4 = { fg = c.blue_muted }
  g.LcarsDashLabel = { fg = c.text_dim }
  g.LcarsDashValue = { fg = c.text, bold = true }
  g.LcarsDashOnline = { fg = c.green, bold = true }
  g.LcarsDashStandby = { fg = c.amber }
  g.LcarsDashOffline = { fg = c.gray }
  g.LcarsDashAlert = { fg = c.red_bright, bold = true }
  g.LcarsDashCascade = { fg = c.blue_muted }
  g.LcarsDashCascadeHi = { fg = c.sky }
  g.LcarsDashBoot = { fg = c.amber, italic = true }
  g.LcarsDashId = { fg = c.gray }
  g.LcarsStatusTitle = { fg = c.black, bg = c.orange, bold = true }
  g.LcarsStatusSection = { fg = c.orange, bold = true }
  g.LcarsStatusLabel = { fg = c.text_dim }
  g.LcarsStatusValue = { fg = c.text, bold = true }
  g.LcarsStatusOk = { fg = c.green, bold = true }
  g.LcarsStatusWarn = { fg = c.amber, bold = true }
  g.LcarsStatusErr = { fg = c.red_bright, bold = true }
  g.LcarsStatusDim = { fg = c.gray }
  g.LcarsStatusBorder = { fg = c.orange, bg = float_bg }
  g.LcarsAlertBlock = { fg = c.black, bg = c.red_bright, bold = true }
  g.LcarsAlertCap = { fg = c.red_bright, bg = "NONE" }
  g.LcarsAlertText = { fg = c.red_bright, bg = "NONE", bold = true }
  g.LcarsCenterIdx = { fg = c.black, bg = c.amber, bold = true }
  g.LcarsCenterText = { fg = c.text }
  g.LcarsCenterDesc = { fg = c.gray }

  return g
end

--- Groups overridden while Red Alert is active.
function M.alert()
  local c = P.colors
  return {
    FloatBorder = { fg = c.red_bright },
    FloatTitle = { fg = c.black, bg = c.red_bright, bold = true },
    WinSeparator = { fg = c.red },
    CursorLineNr = { fg = c.red_bright, bold = true },
    LcarsRail = { fg = c.red },
    LcarsWinbarSep = { fg = c.red_bright },
    LcarsWinbarId = { fg = c.black, bg = c.red_bright, bold = true },
    LcarsWinbarIdCap = { fg = c.red_bright },
    SnacksPickerBorder = { fg = c.red_bright },
    SnacksPickerTitle = { fg = c.black, bg = c.red_bright, bold = true },
    SnacksPickerInputBorder = { fg = c.tomato },
    SnacksPickerInputTitle = { fg = c.black, bg = c.tomato, bold = true },
    SnacksPickerListBorder = { fg = c.red_bright },
    SnacksPickerBoxBorder = { fg = c.red_bright },
    SnacksNotifierBorderInfo = { fg = c.red },
    SnacksNotifierTitleInfo = { fg = c.black, bg = c.red, bold = true },
    NoiceCmdlinePopupBorder = { fg = c.red_bright },
    NoiceCmdlinePopupTitle = { fg = c.black, bg = c.red_bright, bold = true },
    NoiceCmdlineIcon = { fg = c.red_bright, bold = true },
    WhichKeyBorder = { fg = c.red_bright },
    WhichKeyTitle = { fg = c.black, bg = c.red_bright, bold = true },
    LcarsDashBar = { fg = c.red_bright },
    LcarsDashTitle = { fg = c.black, bg = c.red_bright, bold = true },
    LcarsStatusTitle = { fg = c.black, bg = c.red_bright, bold = true },
    LcarsStatusBorder = { fg = c.red_bright },
    DiagnosticVirtualTextError = { fg = c.red_bright, bg = "#2a0a0a", bold = true },
    DiagnosticVirtualTextWarn = { fg = c.orange, bg = "#2a1408", bold = true },
    BlinkCmpMenuBorder = { fg = c.red },
  }
end

return M
