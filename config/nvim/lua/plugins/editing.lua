---@module 'lazy'
---@type LazySpec
return {
  { 'NMAC427/guess-indent.nvim', opts = {} },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
      current_line_blame = true,
      current_line_blame_opts = { delay = 300 }, ---@diagnostic disable-line: missing-fields
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gb', function() require('gitsigns').blame_line { full = true } end, { buffer = bufnr, desc = '[G]it [B]lame line' })
      end,
    },
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters = {
        -- csharpier honours .editorconfig, unlike `dotnet format`.
        -- Note: max_line_length is ignored by both, do not expect it to work.
        csharpier = {
          command = 'csharpier',
          args = { 'format', '--write-stdout' },
          to_stdin = true,
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        cs = { 'csharpier' },
        xml = { 'csharpier' }, -- .csproj / .props
        -- razor is deliberately absent: no formatter handles it, so conform
        -- falls back to the LSP (html-lsp) via lsp_format = 'fallback'.
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        htmlangular = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        scss = { 'prettierd', 'prettier', stop_after_first = true },
        less = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },

  {
    'MagicDuck/grug-far.nvim',
    ---@module 'grug-far'
    ---@type grug.far.OptionsOverride
    opts = {},
    cmd = { 'GrugFar', 'GrugFarWithin' },
    keys = {
      {
        '<leader>gf',
        function() require('grug-far').open() end,
        desc = '[G]rep and replace in [F]iles',
      },
      {
        '<leader>gf',
        function() require('grug-far').with_visual_selection() end,
        mode = 'v',
        desc = '[G]rep and replace selection in [F]iles',
      },
    },
  },

  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- use latest release, remove to use latest commit
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- this will be removed in 4.0.0
      workspaces = {
        {
          name = 'brain',
          path = '~/brain',
        },
      },
      templates = {
        subdir = '10-Templates', -- <‑‑ the folder you just created
        date_format = '%Y-%m-%d', -- optional, used for {{date}} in the templates
        -- optional: you can give the template files a friendly name
        --   (the name that will appear in the picker)
        template_names = {
          ['media'] = 'Media-Synthesis-Template.md',
          ['idea'] = 'Idea-Synthesis-Template.md',
          ['article'] = 'Article-Template.md',
          ['project'] = 'Project-Template.md',
          ['game'] = 'Game-Concept-Template.md',
          ['fiction'] = 'Fiction-Template.md',
          ['biz'] = 'Business-Template.md',
        },
      },
    },
  },

  {
    'kdheepak/lazygit.nvim',
    cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    dependencies = { { 'nvim-lua/plenary.nvim', lazy = true } },
    keys = {
      { '<leader>lz', '<cmd>LazyGit<cr>', desc = '[L]a[z]ygit' },
    },
  },
}
