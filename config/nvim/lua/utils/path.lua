local M = {}

function M.setup_launch_dir()
  local launch_dir = vim.fn.getcwd()
  local first_arg = vim.fn.argv(0)
  if first_arg ~= nil and first_arg ~= '' and vim.fn.isdirectory(first_arg) == 1 then
    launch_dir = vim.fn.fnamemodify(first_arg, ':p')
    vim.cmd.cd(vim.fn.fnameescape(launch_dir))
  end
  M.launch_dir = launch_dir
end

function M.absolute(bufnr)
  local value = vim.api.nvim_buf_get_name(bufnr or 0)
  if value == '' then return end
  return vim.uv.fs_realpath(value) or vim.fs.normalize(vim.fn.fnamemodify(value, ':p'))
end

return M
