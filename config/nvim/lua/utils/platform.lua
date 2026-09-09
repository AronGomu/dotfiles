local is_windows = vim.fn.has 'win32' == 1

return {
  is_windows = is_windows,
  make = is_windows and 'mingw32-make' or 'make',
  archive = is_windows and '7z' or 'unzip',
}
