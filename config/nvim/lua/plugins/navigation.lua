local launch_dir = require('utils.path').launch_dir
local theme_picker = require('config.topbar').theme_picker
local platform = require 'utils.platform'
local is_windows = platform.is_windows
local make_command = platform.make
local terminal_shell = is_windows and vim.fn.shellescape(vim.fs.joinpath(vim.fn.stdpath 'config', 'bin', 'pwsh.cmd')) or vim.o.shell

local function find_windows_realpath()
  if not is_windows then return end

  local direct = vim.fn.exepath 'realpath'
  if direct ~= '' then return direct end

  local git_dir = vim.fs.dirname(vim.fn.exepath 'git')
  local candidates = {
    vim.fs.normalize(vim.fs.joinpath(git_dir, '..', 'usr', 'bin', 'realpath.exe')),
    vim.fs.normalize(vim.fs.joinpath(git_dir, '..', '..', 'usr', 'bin', 'realpath.exe')),
  }
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
end

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    keys = {
      {
        '<leader>t',
        function()
          local manager = require 'neo-tree.sources.manager'
          local state = manager.get_state 'filesystem'

          if state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
            vim.cmd 'Neotree close'
            return
          end

          -- Clean up stale hidden Neo-tree buffers. They can be left behind when
          -- starting Neovim with a directory argument like `nvim .`, and Neo-tree
          -- may otherwise fail with E95 when naming its new tree buffer.
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr):match 'neo%-tree filesystem %[%d+%]$' then
              pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
          end

          local cwd = launch_dir or vim.uv.cwd()
          local project_root = vim.fn.systemlist({ 'git', '-C', cwd, 'rev-parse', '--show-toplevel' })[1]
          if vim.v.shell_error ~= 0 or project_root == nil or project_root == '' then project_root = cwd end

          local sep = package.config:sub(1, 1)
          local current_file = vim.api.nvim_buf_get_name(0)
          local current_real = current_file ~= '' and vim.uv.fs_realpath(current_file) or nil
          local root_real = vim.uv.fs_realpath(project_root) or project_root
          local current_is_in_project = current_real
            and vim.fn.filereadable(current_real) == 1
            and (current_real == root_real or current_real:sub(1, #root_real + 1) == root_real .. sep)

          if current_is_in_project then
            vim.cmd('Neotree filesystem dir=' .. vim.fn.fnameescape(project_root) .. ' reveal_file=' .. vim.fn.fnameescape(current_real))
          else
            vim.cmd('Neotree filesystem show dir=' .. vim.fn.fnameescape(project_root))
            vim.schedule(function()
              state = manager.get_state 'filesystem'
              if state and state.tree then pcall(require('neo-tree.sources.common.commands').close_all_nodes, state) end
            end)
          end
        end,
        desc = 'Toggle file tree',
      },
    },
    config = function()
      local preview_group = vim.api.nvim_create_augroup('neo-tree-auto-preview', { clear = true })
      local preview_win
      local preview_buf
      local preview_path

      local function close_preview()
        if preview_win and vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then vim.api.nvim_buf_delete(preview_buf, { force = true }) end
        preview_win = nil
        preview_buf = nil
        preview_path = nil
      end

      local function show_preview(state, path)
        if preview_path == path and preview_win and vim.api.nvim_win_is_valid(preview_win) then return end
        close_preview()

        local ok, lines = pcall(vim.fn.readfile, path, '', 500)
        if not ok then return end

        preview_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
        vim.bo[preview_buf].bufhidden = 'wipe'
        vim.bo[preview_buf].buftype = 'nofile'
        vim.bo[preview_buf].modifiable = false
        local filetype = vim.filetype.match { filename = path } or ''
        vim.bo[preview_buf].filetype = filetype
        vim.bo[preview_buf].syntax = filetype

        local function start_treesitter()
          local language = vim.treesitter.language.get_lang(filetype)
          if not language or not vim.api.nvim_buf_is_valid(preview_buf) then return end
          pcall(vim.treesitter.start, preview_buf, language)
        end

        local tree_width = vim.api.nvim_win_get_width(state.winid)
        local width = math.min(100, vim.o.columns - tree_width - 4)
        local height = math.min(vim.o.lines - 6, math.max(10, #lines))
        if width < 10 or height < 5 then return end

        preview_win = vim.api.nvim_open_win(preview_buf, false, {
          relative = 'editor',
          row = 1,
          col = tree_width + 2,
          width = width,
          height = height,
          border = 'rounded',
          title = ' Preview ',
          title_pos = 'left',
          focusable = false,
          style = 'minimal',
        })
        vim.wo[preview_win].number = true
        preview_path = path

        vim.schedule(start_treesitter)
      end

      require('neo-tree').setup {
        popup_border_style = 'rounded',
        event_handlers = {
          {
            event = 'neo_tree_buffer_enter',
            handler = function()
              local bufnr = vim.api.nvim_get_current_buf()

              vim.api.nvim_clear_autocmds { group = preview_group, buffer = bufnr }
              vim.api.nvim_create_autocmd('CursorMoved', {
                group = preview_group,
                buffer = bufnr,
                callback = function()
                  local manager = require 'neo-tree.sources.manager'
                  local state = manager.get_state 'filesystem'
                  if
                    not state
                    or not state.tree
                    or not state.winid
                    or not vim.api.nvim_win_is_valid(state.winid)
                    or vim.api.nvim_get_current_win() ~= state.winid
                  then
                    close_preview()
                    return
                  end

                  local ok, node = pcall(state.tree.get_node, state.tree)
                  if ok and node and node.type == 'file' then
                    show_preview(state, node.path)
                  else
                    close_preview()
                  end
                end,
              })
            end,
          },
          {
            event = 'neo_tree_buffer_leave',
            handler = close_preview,
          },
          {
            event = 'file_opened',
            handler = function()
              close_preview()
              require('neo-tree.command').execute { action = 'close' }
            end,
          },
        },
        filesystem = {
          follow_current_file = { enabled = false },
          hijack_netrw_behavior = 'disabled',
        },
      }
    end,
  },

  -- NOTE: Plugins can specify dependencies.

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = make_command,

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function() return vim.fn.executable(make_command) == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },

    config = function()
      local function truncate_path(max, path)
        if #path > max then return '...' .. string.sub(path, -(max - 3)) end
        return path
      end

      local function smart_truncate_path(_, path, only_filename)
        local max = 65 -- change width here

        local sep = package.config:sub(1, 1) -- get separator on any OS by extracting the first char of the path
        local parts = vim.split(path, sep)
        local filename = parts[#parts] -- get the last element of the array
        local dir_path = ''
        for i = 1, #parts - 1 do
          dir_path = dir_path .. parts[i] .. sep
        end

        if only_filename then
          return truncate_path(max, filename)
        else
          return truncate_path(max, dir_path .. filename)
        end
      end

      require('telescope').setup {
        defaults = {
          path_display = function(_, path) return smart_truncate_path(_, path, false) end,
          layout_config = { width = 0.9 },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- Track files as you visit them, newest first, so <leader>fr can show
      -- a project-local MRU (most recently used) list instead of Telescope's
      -- global oldfiles list.
      local recent_project_files = {}

      local function normalize_path(path) return vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p') end

      local function is_inside_project(path)
        local cwd = normalize_path(vim.loop.cwd())
        path = normalize_path(path)
        return path == cwd or path:sub(1, #cwd + 1) == cwd .. package.config:sub(1, 1)
      end

      local function remember_file(path)
        if path == nil or path == '' or vim.fn.filereadable(path) ~= 1 or not is_inside_project(path) then return end

        path = normalize_path(path)

        for i = #recent_project_files, 1, -1 do
          if recent_project_files[i] == path then table.remove(recent_project_files, i) end
        end

        table.insert(recent_project_files, 1, path)
      end

      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('project-recent-files', { clear = true }),
        callback = function(args) remember_file(vim.api.nvim_buf_get_name(args.buf)) end,
      })

      local function project_recent_files()
        local seen = {}
        local results = {}
        local current_path = normalize_path(vim.api.nvim_buf_get_name(0))

        local function add(path)
          if path == nil or path == '' or vim.fn.filereadable(path) ~= 1 or not is_inside_project(path) then return end
          path = normalize_path(path)
          if path == current_path or seen[path] then return end
          seen[path] = true
          table.insert(results, path)
        end

        -- First: files visited in this Neovim session, ordered newest to oldest.
        for _, path in ipairs(recent_project_files) do
          add(path)
        end

        -- Then: persisted oldfiles from this project only, also newest to oldest.
        for _, path in ipairs(vim.v.oldfiles) do
          add(path)
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Recent Project Files',
            finder = require('telescope.finders').new_table {
              results = results,
              entry_maker = function(path)
                return {
                  value = path,
                  ordinal = path,
                  display = smart_truncate_path(nil, path, true),
                  path = path,
                }
              end,
            },
            sorter = require('telescope.config').values.generic_sorter {},
            previewer = require('telescope.config').values.file_previewer {},
          })
          :find()
      end

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.api.nvim_create_user_command('Themes', function()
        local colors = vim.fn.getcompletion('', 'color')
        local longest_name = 0
        for _, color in ipairs(colors) do
          longest_name = math.max(longest_name, vim.fn.strdisplaywidth(color))
        end

        local picker_width = math.min(vim.o.columns - 2, longest_name + 6)
        local picker_height = math.min(vim.o.lines - 2, #colors + 4)
        local options = require('telescope.themes').get_dropdown {
          colors = colors,
          enable_preview = true,
          prompt_title = false,
          results_title = false,
          preview_title = false,
          prompt_prefix = '  ',
          selection_caret = '  ',
          entry_prefix = '  ',
          layout_config = {
            width = picker_width,
            height = picker_height,
            prompt_position = 'top',
            preview_cutoff = math.huge,
          },
        }

        theme_picker.active = true
        theme_picker.selected = vim.g.colors_name or 'default'
        vim.cmd.redrawtabline()

        local opened, error_message = pcall(builtin.colorscheme, options)
        if not opened then
          theme_picker.active = false
          theme_picker.selected = nil
          vim.cmd.redrawtabline()
          error(error_message)
        end
      end, { desc = 'Preview and select an installed colorscheme', force = true })
      -- User commands must start uppercase, so expose the requested lowercase spelling as an exact command-line alias.
      vim.cmd [[cnoreabbrev <expr> themes getcmdtype() ==# ':' && getcmdline() ==# 'themes' ? 'Themes' : 'themes']]

      local search_layout = {
        layout_strategy = 'vertical',
        layout_config = {
          width = 0.9,
          height = 0.9,
          prompt_position = 'bottom',
          preview_cutoff = 1,
          -- Leave five result rows below the preview (plus the prompt and borders).
          preview_height = function(_, _, height) return math.max(1, height - 12) end,
        },
      }

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', function() builtin.find_files(search_layout) end, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        builtin.live_grep(vim.tbl_deep_extend('force', search_layout, {
          path_display = function(_, path) return smart_truncate_path(_, path, true) end,
        }))
      end, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>fr', project_recent_files, { desc = '[F]iles [R]ecent Project' })
      vim.keymap.set('n', '<leader>sz', function()
        builtin.oldfiles { path_display = function(_, path) return smart_truncate_path(_, path, true) end }
      end, { desc = '[S]earch Recent Files from all projects' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader>s.', builtin.buffers, { desc = ' [S]earch existing buffers (.)' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      -- Override default behavior and theme when searching
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set(
        'n',
        '<leader>s/',
        function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[S]earch [/] in Open Files' }
      )
    end,
  },

  {
    'rmagatti/auto-session',
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {},
  },

  {
    'mikavilpas/yazi.nvim',
    version = '*',
    dependencies = { { 'nvim-lua/plenary.nvim', lazy = true } },
    keys = {
      { '<leader>r', '<cmd>Yazi<CR>', desc = 'Open Yazi file manager' },
    },
    opts = function()
      local windows_realpath = find_windows_realpath()
      return {
        open_for_directories = false,
        integrations = windows_realpath and { resolve_relative_path_application = windows_realpath } or nil,
        keymaps = not windows_realpath and { copy_relative_path_to_selected_files = false } or nil,
      }
    end,
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon [A]dd file' })
      vim.keymap.set('n', '<leader>H', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Open [H]arpoon menu' })

      for i = 1, 9 do
        local slot = i
        vim.keymap.set('n', '<leader><leader>' .. slot, function() harpoon:list():replace_at(slot) end, { desc = 'Assign file to Harpoon slot ' .. slot })
      end

      for i = 1, 10 do
        local slot = i
        local key = slot == 10 and '0' or tostring(slot)
        vim.keymap.set('n', '<leader>' .. key, function() harpoon:list():select(slot) end, { desc = 'Harpoon file ' .. slot })
      end
    end,
  },

  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      -- Edit FS like buffer. :w applies renames/deletes/creates.
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ['<C-h>'] = false, -- keep window-nav maps from config/keymaps.lua
        ['<C-l>'] = false,
      },
    },
    dependencies = { { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font } },
    -- oil docs: lazy-load breaks some dir-open cases
    lazy = false,
    keys = {
      { '-', function() require('oil').open() end, desc = 'Open parent dir (oil)' },
      { '<leader>o', function() require('oil').open() end, desc = '[O]il file explorer' },
    },
  },

  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      open_mapping = [[<leader>\]],
      direction = 'horizontal',
      shell = terminal_shell,
      size = function() return math.floor(vim.o.lines / 2) end,
      insert_mappings = false,
      terminal_mappings = true,
    },
  },
}
