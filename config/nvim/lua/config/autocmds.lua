local topbar = require 'config.topbar'

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('PreserveTransparentTheme', { clear = true }),
  desc = 'Keep editor transparency and Powerline colors when switching themes',
  callback = function(args)
    if topbar.theme_picker.active then
      topbar.theme_picker.selected = args.match
      vim.cmd.redrawtabline()
    end
    vim.schedule(topbar.preserve_transparent_theme)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('ThemePickerTopbar', { clear = true }),
  pattern = 'TelescopePrompt',
  desc = 'Restore the filepath in the top bar after closing the theme picker',
  callback = function(args)
    if not topbar.theme_picker.active then return end

    vim.api.nvim_create_autocmd('BufWipeout', {
      buffer = args.buf,
      once = true,
      callback = function()
        topbar.theme_picker.active = false
        topbar.theme_picker.selected = nil
        vim.schedule(function()
          topbar.persist_theme(vim.g.colors_name)
          vim.cmd.redrawtabline()
        end)
      end,
    })
  end,
})

if topbar.persisted_theme ~= nil then
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('PersistedTheme', { clear = true }),
    once = true,
    desc = 'Restore the selected colorscheme after plugins load',
    callback = function()
      vim.schedule(function()
        local applied = pcall(vim.cmd.colorscheme, topbar.persisted_theme)
        if not applied then vim.notify('Saved theme is no longer available: ' .. topbar.persisted_theme, vim.log.levels.WARN, { title = 'Themes' }) end
      end)
    end,
  })
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('dotnet-compiler', { clear = true }),
  pattern = { 'cs', 'razor' },
  desc = 'Send `dotnet build` output to the quickfix list',
  callback = function(args)
    vim.cmd.compiler 'dotnet'
    vim.keymap.set('n', '<leader>mb', function()
      vim.cmd.make()
      vim.cmd.copen()
    end, { buffer = args.buf, desc = '[M]ake: dotnet [b]uild' })
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
