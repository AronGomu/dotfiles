-- Debugging and testing for C# / .NET.
--
-- netcoredbg is expected on PATH (install a native package or compatible Mason build).

---@module 'lazy'
---@type LazySpec
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
      -- Ships the dap-dll-autopicker module (resolves the DLL to launch from
      -- the current project instead of prompting on every F5) and
      -- dap-scope-walker.
      'ramboe/ramboe-dotnet-utils',
    },
    keys = {
      -- Visual Studio style bindings.
      { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
      { '<F9>', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle breakpoint' },
      { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step over' },
      { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step into' },
      { '<F8>', function() require('dap').step_out() end, desc = 'Debug: Step out' },
      { '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Conditional breakpoint' },
      { '<leader>dr', function() require('dap').repl.open() end, desc = 'Debug: REPL' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run last' },
      { '<leader>du', function() require('dapui').toggle() end, desc = 'Debug: Toggle UI' },
      { '<leader>dw', function() require('dapui').eval(nil, { enter = true }) end, mode = { 'n', 'v' }, desc = 'Debug: Evaluate (enter float)' },
      { 'Q', function() require('dapui').eval() end, mode = { 'n', 'v' }, desc = 'Debug: Peek value' },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      local netcoredbg = {
        type = 'executable',
        command = 'netcoredbg',
        args = { '--interpreter=vscode' },
      }

      dap.adapters.netcoredbg = netcoredbg -- plain debugging
      dap.adapters.coreclr = netcoredbg -- what unit test debugging asks for

      dap.configurations.cs = {
        {
          type = 'coreclr',
          name = 'Launch from nvim',
          request = 'launch',
          program = function() return require('dap-dll-autopicker').build_dll_path() end,
        },
        {
          type = 'coreclr',
          name = 'Attach to running process',
          request = 'attach',
          processId = function() return require('dap.utils').pick_process() end,
        },
      }

      vim.fn.sign_define('DapBreakpoint', { text = '⚪', texthl = 'DapBreakpointSymbol', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '⭕', texthl = 'DapStoppedSymbol', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '🔴', texthl = 'DapStoppedSymbol', linehl = 'DapBreakpoint', numhl = '' })

      -- Deliberately minimal: only the variables of the current scope, at the
      -- bottom. No control buttons, no watches, no threads.
      dapui.setup {
        expand_lines = true,
        controls = { enabled = false },
        floating = { border = 'rounded' },
        render = {
          max_type_length = 60,
          max_value_lines = 200,
        },
        layouts = {
          {
            elements = { { id = 'scopes', size = 1.0 } },
            size = 15, -- height in lines
            position = 'bottom',
          },
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
    end,
  },

  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'mfussenegger/nvim-dap',
      -- neotest-dotnet is currently broken; vstest is the maintained path.
      'nsidorenco/neotest-vstest',
    },
    keys = {
      { '<leader>dt', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug nearest test' },
      { '<F6>', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug nearest test' },
      -- <leader>n, not <leader>t: <leader>t alone toggles neo-tree and a
      -- <leader>t* prefix would make it wait for timeoutlen.
      { '<leader>nt', function() require('neotest').run.run() end, desc = 'Test nearest' },
      { '<leader>nf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Test file' },
      { '<leader>ns', function() require('neotest').summary.toggle() end, desc = 'Test summary' },
      { '<leader>no', function() require('neotest').output.open { enter = true } end, desc = 'Test output' },
    },
    config = function()
      require('neotest').setup {
        adapters = { require 'neotest-vstest' },
      }
    end,
  },

  {
    -- :DapScopeWalk <property> expands a deep object graph down to the property
    -- you are actually after, instead of clicking through every level.
    -- (The fzf-lua razor outline picker in this repo is not wired up, this
    -- config uses telescope.)
    'ramboe/ramboe-dotnet-utils',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function() require('dap-scope-walker').setup {} end,
  },
}
