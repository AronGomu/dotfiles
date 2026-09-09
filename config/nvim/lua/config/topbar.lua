local path = require 'utils.path'

local M = {
  theme_picker = { active = false, selected = nil },
}

local function shorten_path(value)
  local available_width = math.max(vim.o.columns - 2, 1)
  if vim.fn.strdisplaywidth(value) <= available_width then return value end

  local separator = package.config:sub(1, 1)
  local prefix = value:sub(1, 1) == separator and separator or ''
  local path_without_prefix = prefix == '' and value or value:sub(2)
  local parts = vim.split(path_without_prefix, separator, { plain = true })
  local shortened = value

  for index = 1, #parts - 1 do
    local abbreviation = vim.fn.strcharpart(parts[index], 0, 3) .. '...'
    if vim.fn.strdisplaywidth(abbreviation) < vim.fn.strdisplaywidth(parts[index]) then parts[index] = abbreviation end

    shortened = prefix .. table.concat(parts, separator)
    if vim.fn.strdisplaywidth(shortened) <= available_width then return shortened end
  end

  return shortened
end

local theme_state_path = vim.fn.stdpath 'state' .. '/selected-theme'

local function read_persisted_theme()
  local readable, lines = pcall(vim.fn.readfile, theme_state_path)
  if readable and lines[1] ~= nil and lines[1] ~= '' then return lines[1] end
end

M.persisted_theme = read_persisted_theme()

function M.persist_theme(theme)
  if theme == nil or theme == '' then return end

  vim.fn.mkdir(vim.fn.fnamemodify(theme_state_path, ':h'), 'p')
  local written, result = pcall(vim.fn.writefile, { theme }, theme_state_path)
  if not written or result == -1 then
    vim.notify('Could not save theme selection', vim.log.levels.WARN, { title = 'Themes' })
    return
  end
  M.persisted_theme = theme
end

function M.path()
  if M.theme_picker.active then return 'Theme: ' .. (M.theme_picker.selected or vim.g.colors_name or 'default') end

  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' then return '' end

  local value = path.absolute(bufnr)
  if value == nil then return '[No File Selected]' end

  value = vim.fn.fnamemodify(value, ':~')
  return shorten_path(value)
end

local function highlight_color(groups, attribute, fallback)
  for _, group in ipairs(groups) do
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attribute]
    if value ~= nil then return value end
  end
  return fallback
end

function M.preserve_transparent_theme()
  local dark_theme = vim.o.background == 'dark'
  local fallback_bg = dark_theme and 0x282c34 or 0xf0f0f0
  local fallback_fg = dark_theme and 0xabb2bf or 0x383a42
  local normal_bg = highlight_color({ 'Normal' }, 'bg', highlight_color({ 'MiniStatuslineModeNormal' }, 'fg', fallback_bg))
  local normal_fg = highlight_color({ 'Normal' }, 'fg', fallback_fg)
  local muted_fg = highlight_color({ 'Comment', 'LineNr' }, 'fg', normal_fg)
  local filename_bg = highlight_color({ 'StatusLine', 'StatusLineNC', 'Pmenu' }, 'bg', normal_bg)
  local info_bg = highlight_color({ 'MiniStatuslineDevinfo', 'Pmenu', 'NormalFloat' }, 'bg', filename_bg)

  if info_bg == filename_bg then info_bg = highlight_color({ 'CursorLine', 'Visual' }, 'bg', filename_bg) end

  local accents = {
    Normal = highlight_color({ 'MiniStatuslineModeNormal' }, 'bg', highlight_color({ 'String', 'DiagnosticOk' }, 'fg', 0x98c379)),
    Insert = highlight_color({ 'MiniStatuslineModeInsert' }, 'bg', highlight_color({ 'Function', 'DiagnosticInfo' }, 'fg', 0x61afef)),
    Visual = highlight_color({ 'MiniStatuslineModeVisual' }, 'bg', highlight_color({ 'Keyword', 'Statement' }, 'fg', 0xc678dd)),
    Replace = highlight_color({ 'MiniStatuslineModeReplace' }, 'bg', highlight_color({ 'DiagnosticError', 'ErrorMsg' }, 'fg', 0xe06c75)),
    Command = highlight_color({ 'MiniStatuslineModeCommand' }, 'bg', highlight_color({ 'DiagnosticWarn', 'WarningMsg' }, 'fg', 0xd19a66)),
    Other = highlight_color({ 'MiniStatuslineModeOther' }, 'bg', highlight_color({ 'DiagnosticHint', 'Special' }, 'fg', 0x56b6c2)),
  }
  local git_accent = highlight_color({ 'MiniStatuslineGit' }, 'bg', highlight_color({ 'DiagnosticWarn', 'Character' }, 'fg', 0xe5c07b))

  for _, group in ipairs {
    'Normal',
    'NormalNC',
    'EndOfBuffer',
    'SignColumn',
    'FoldColumn',
    'CursorLine',
    'CursorColumn',
    'ColorColumn',
    'LineNr',
    'CursorLineNr',
  } do
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    if next(highlight) ~= nil then
      highlight.bg = nil
      vim.api.nvim_set_hl(0, group, highlight)
    end
  end

  vim.api.nvim_set_hl(0, 'StatusLine', { fg = normal_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = muted_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGit', { fg = normal_bg, bg = git_accent, bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitSep', { fg = git_accent, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitSepFilename', { fg = git_accent, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineInfoSep', { fg = info_bg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = normal_fg, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = normal_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = normal_fg, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = muted_fg, bg = filename_bg })

  for mode, accent in pairs(accents) do
    local group = 'MiniStatuslineMode' .. mode
    vim.api.nvim_set_hl(0, group, { fg = normal_bg, bg = accent, bold = true })
    vim.api.nvim_set_hl(0, group .. 'GitSep', { fg = accent, bg = git_accent })
    vim.api.nvim_set_hl(0, group .. 'Sep', { fg = accent, bg = info_bg })
    vim.api.nvim_set_hl(0, group .. 'SepFilename', { fg = accent, bg = filename_bg })
  end
end

_G.nvim_topbar_path = M.path
vim.o.showtabline = 2
vim.o.tabline = '%#TabLineFill# %{v:lua.nvim_topbar_path()} '

return M
