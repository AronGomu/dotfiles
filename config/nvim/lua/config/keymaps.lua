local path = require 'utils.path'

vim.api.nvim_create_user_command('Q', 'quitall', { desc = 'Quit Neovim' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>yp', function()
  local absolute_path = path.absolute()
  if absolute_path == nil then
    vim.notify('Current buffer has no file path', vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('+', absolute_path)
  vim.notify('Copied path: ' .. absolute_path)
end, { desc = '[Y]ank absolute file [P]ath' })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
