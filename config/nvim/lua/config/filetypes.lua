vim.filetype.add {
  extension = {
    -- Razor / Blazor: roslyn_ls attaches to these, and the razor treesitter
    -- parser needs the filetype to exist.
    razor = 'razor',
    cshtml = 'razor',
    html = function(path)
      if vim.fs.root(path, { 'angular.json', 'nx.json' }) then return 'htmlangular' end
      return 'html'
    end,
  },
}
