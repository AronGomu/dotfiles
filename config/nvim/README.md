# AronGomu Neovim config

Personal Neovim config built from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Focus: project navigation, fast search, Angular/TypeScript tooling, transparent themes, keyboard-first workflows.

## Highlights

- Modular `config/`, `plugins/`, `utils/` Lua tree
- `lazy.nvim` plugin mgmt with automatic bootstrap
- Top bar showing absolute file paths with `$HOME` shortened to `~/`
- Transparent `onedark` default theme
- `:Themes` Telescope picker with live preview + persisted selection
- Powerline-style `mini.statusline` with mode, Git branch, diagnostics, LSP, file info, location
- Neo-tree project explorer with automatic syntax-highlighted file preview
- Oil editable FS buffers
- Telescope file, text, command, buffer, diagnostic, LSP search
- Project-local recent-file history
- Harpoon slots for fast file switching
- Grug Far project-wide search/replace
- Toggleterm horizontal terminal
- LSP, completion, formatting for Lua + web dev
- Angular project detection via `angular.json` or `nx.json`
- Tree-sitter parser auto-install
- Session restore, Git signs, TODO highlights, cursor animation, inline diagnostics
- Obsidian workspace support for `~/brain`

## Requirements

- Neovim 0.11.x (`nvim-treesitter`'s compatibility branch does not support Neovim 0.12)
- Git
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/tree/master/crates/cli) 0.25.x
- Clipboard provider: `xclip`, `xsel`, `wl-clipboard`, `win32yank`, or OS equivalent
- Nerd Font
- Node.js + npm for TypeScript, Angular, HTML/CSS LSPs, Prettier

## Platform behavior

| Platform | `<leader>r` | Terminal | Native build | Archive tool |
|---|---|---|---|---|
| Linux/macOS | [Yazi](https://yazi-rs.github.io/) | User shell | C compiler + `make` | `unzip` |
| Windows 11 | [Yazi](https://yazi-rs.github.io/) | PowerShell 7 | C compiler + `mingw32-make` | `7z` |

Install tools from the matching row before first launch. Shared plugins and keymaps remain identical across platforms.

## Install

Back up existing config first.

### Linux/macOS

```sh
git clone https://github.com/AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

### Windows PowerShell

```powershell
git clone https://github.com/AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX.git "$env:LOCALAPPDATA\nvim"
nvim
```

First launch installs plugins, LSP servers, formatters, Tree-sitter parsers. Run `:Lazy` or `:Mason` to inspect progress.

`lazy-lock.json` stays local because repo ignores it. `nvim-treesitter` stays on its `master` compatibility branch for Neovim 0.10/0.11; its `main` branch requires Neovim 0.12+. After branch changes, refresh plugin + parsers:

```vim
:Lazy update nvim-treesitter
:TSUpdate
```

## Project behavior

Start Neovim from project root:

```sh
nvim .
```

Config uses launch dir to:

- resolve Git root
- root Neo-tree
- filter recent project files

Top bar always shows canonical absolute file paths. Paths under `$HOME` use `~/`.

Angular workspaces receive:

- `htmlangular` template filetype
- Angular Language Service for TypeScript + templates
- HTML/CSS LSP support outside Angular templates
- TypeScript Tools with Angular-aware rename handling
- Prettier/Prettierd formatting
- Angular, HTML, CSS, JavaScript, SCSS, TypeScript Tree-sitter parsers

Angular template buffers keep the `htmlangular` filetype locally, but Angular LSP receives the standard `html` language ID.

## Keymaps

Leader key: `Space`.

### Core

| Key | Action |
|---|---|
| `<Esc>` | Clear search highlight |
| `<Esc><Esc>` | Exit terminal mode or return from focused LSP docs |
| `<C-h/j/k/l>` | Move across splits |
| `<leader>q` | Open diagnostic location list |
| `<leader>f` | Format current buffer |
| `<leader>th` | Toggle LSP inlay hints |
| `:Q` | Quit all Neovim windows |

### Files + navigation

| Key | Action |
|---|---|
| `<leader>t` | Toggle project-rooted Neo-tree |
| `-` | Open parent dir in Oil |
| `<leader>o` | Open Oil |
| `<leader>r` | Open Ranger (Linux/macOS) or Yazi (Windows) |
| `<leader>yp` | Copy absolute file path to system clipboard |
| `<leader>a` | Add file to Harpoon |
| `<leader><leader>1` … `<leader><leader>9` | Assign file to Harpoon slot 1–9 |
| `<leader>1` … `<leader>0` | Select Harpoon slots 1–10 |
| `<leader>H` | Open Harpoon menu |
| `<leader>\` | Toggle horizontal terminal |

### Search

| Key | Action |
|---|---|
| `<leader>sf` | Find files |
| `<leader>sg` | Live grep |
| `<leader>sw` | Search word/visual selection |
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader>ss` | Search Telescope pickers |
| `<leader>sd` | Search diagnostics |
| `<leader>sc` | Search commands |
| `<leader>s.` | Search open buffers |
| `<leader>sr` | Resume previous search |
| `<leader>fr` | Recent files in current project |
| `<leader>sz` | Recent files across projects |
| `<leader>/` | Fuzzy search current buffer |
| `<leader>s/` | Grep open files |

### Search + replace

| Key | Mode | Action |
|---|---|---|
| `<leader>sR` | Normal | Open Grug Far |
| `<leader>sR` | Visual | Replace visual selection |
| `<leader>sW` | Normal | Replace word under cursor |

### Git

| Key | Action |
|---|---|
| `<leader>gb` | Open blame |
| `<leader>go` | Open file/folder in Git remote |
| `<leader>gp` | Open current branch pull request |
| `<leader>gn` | Create pull request |
| `<leader>gd` | Diff against index |
| `<leader>gD` | Close diff |
| `<leader>gr` | Revert to commit |
| `<leader>gR` | Revert current file to commit |

### LSP

| Key | Action |
|---|---|
| `gd` / `grd` | Definition |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `grD` | Declaration |
| `grn` | Rename |
| `gra` | Code action |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `K` / `KK` | Show / focus hover docs |

### Completion

| Key | Action |
|---|---|
| `<C-Space>` | Open completion menu or docs |
| `<C-y>` | Accept completion |
| `<C-n>` / `<C-p>` | Select next / previous item |
| `<C-e>` | Close completion menu |
| `<C-k>` | Toggle signature help |

Use `which-key` for discoverable key groups.

## Themes

Default: transparent `onedark`.

Open theme picker:

```vim
:Themes
```

Lowercase alias also works:

```vim
:themes
```

Selection persists under Neovim state dir as `selected-theme`. Theme changes preserve editor transparency + statusline colors.

Included theme families: Catppuccin, Tokyo Night, Kanagawa, Rose Pine, Nightfox, Gruvbox Material, GitHub, Everforest, Cyberdream, VS Code, Onedark Pro, Dracula, Nord, Oxocarbon, Material, Solarized Osaka, Sonokai, Nordic, Moonfly, Tokyodark, Bamboo, Melange, Edge.

## Tooling

### LSP

Mason installs/configures:

- `lua_ls`
- `angularls`
- `html`
- `cssls`
- TypeScript Language Server for `typescript-tools.nvim`

Completion uses `blink.cmp` with LSP, path, LuaSnip sources, signature help. Suggestions show auto-import modules; docs open automatically.

### Formatting

`conform.nvim` formats on save. Manual format: `<leader>f`.

- Lua: Stylua
- JS/JSX/TS/TSX/HTML/Angular/CSS/SCSS/Less/JSON/YAML/Markdown: Prettierd, fallback Prettier
- C/C++: no format-on-save fallback

### Tree-sitter

Configured parsers:

`angular`, `bash`, `c`, `css`, `diff`, `html`, `javascript`, `json`, `lua`, `luadoc`, `markdown`, `markdown_inline`, `query`, `scss`, `typescript`, `vim`, `vimdoc`.

Missing supported parsers install when matching files open.

## Structure

```text
.
├── bin/pwsh.cmd                   # Windows launcher for PowerShell App Execution Alias
├── init.lua                       # ordered config entrypoint
├── lua/
│   ├── config/
│   │   ├── options.lua            # globals, editor opts, diagnostics
│   │   ├── keymaps.lua            # global keymaps + commands
│   │   ├── autocmds.lua           # global autocmds
│   │   ├── filetypes.lua          # custom filetype detection
│   │   ├── topbar.lua             # path display, theme state, highlights
│   │   └── lazy.lua               # lazy.nvim bootstrap + plugin import
│   ├── plugins/
│   │   ├── completion.lua         # blink.cmp + snippets
│   │   ├── editing.lua            # formatting, Git, search/replace, notes
│   │   ├── lsp.lua                # LSP, Mason, TypeScript, diagnostics
│   │   ├── navigation.lua         # Neo-tree, Telescope, Harpoon, Oil
│   │   ├── treesitter.lua         # parser/highlight config
│   │   └── ui.lua                 # themes, statusline, which-key, cursor
│   ├── utils/
│   │   ├── path.lua               # shared canonical-path helpers
│   │   └── platform.lua           # OS-specific commands and feature gates
│   └── kickstart/plugins/         # optional Kickstart plugin examples
└── .stylua.toml                   # Lua formatting rules
```

`init.lua` loads core modules in dependency order. `config/lazy.lua` imports every domain spec from `plugins/`; shared path behavior lives in `utils/path.lua`.

## Maintenance

```vim
:Lazy          " plugins
:Mason         " LSPs/tools
:ConformInfo   " formatter status
:checkhealth   " Neovim health
```

Update plugins:

```vim
:Lazy update
```

Format Lua config with Stylua:

```sh
stylua init.lua lua/
```
