# Ownership / deployment map

Repo identity: **dotfiles**. Suggested checkout `~/config/dotfiles`; installer may choose another path. `<repo>` below means inspected root containing this file + root `AGENTS.md`, not assumed cwd. Root `AGENTS.md` is sole installer guide.

`$XDG_CONFIG_HOME` defaults to `$HOME/.config`; `$XDG_DATA_HOME` defaults to `$HOME/.local/share`. Explicit application conventions (`~/.pi/agent`, `~/.claude`, `~/.codex`) override generic XDG assumptions; inspect current CLI support before relocating them.

| ID | Owned source | Runtime destination / mode |
|---|---|---|
| D1 | `config/nvim/` | `$XDG_CONFIG_HOME/nvim/`: real writable copy, merge conflicts first. Keep init/Lua/docs/platform helper + lockfile. Runtime lazy plugins/parsers/cache remain outside repo. Reconcile only intentional lock changes. |
| D2 | `config/agents/GLOBAL_RULES.md` | `~/.agents/GLOBAL_RULES.md`: direct link to reviewed source or copy. Pi `~/.pi/agent/APPEND_SYSTEM.md` loads same text. Claude memory points here; Codex global instructions must point here. |
| D3 | `config/agents/skills/` | `~/.agents/skills/`: canonical shared hub. Direct link if destination absent; otherwise compare/merge individual skills. Claude `~/.claude/skills`, Codex `~/.codex/skills`, Pi discovery path each connect to hub exactly once; no extra graphify copy. |
| D4 | `vendor/skills/` | **Not auto-deployed.** Compare current Codex bundled system skills by name/version. Prefer installed bundle; choose snapshot only if needed. Never place entire snapshot in shared hub alongside bundled copies. Licenses travel with chosen source. |
| D5 | `config/pi/agent/settings.json` | `~/.pi/agent/settings.json`: writable seed/merge; preserve runtime defaultProvider/defaultModel/defaultThinkingLevel; union enabledModels. Do not copy auth, trust, sessions, onboarding counters. Other prefs reviewed key-by-key. |
| D6 | `config/pi/agent/{configs,extensions,prompts,keybindings.json,claude-bridge.json}` | Matching `~/.pi/agent/` paths. Source extensions/prompts may link; configs writable seeds. `env.example` is documentation, never live secrets. Two Herdr integration files are source snapshots; let current Herdr regenerate managed integration only after comparison, preserve custom sidecar. |
| D7 | `config/claude/` | `~/.claude/`: prefs + CLAUDE.md writable seeds; commands/statusline link/copy. Retained permissive settings require explicit review; no reminders/trust/hashes exported. |
| D8 | `config/codex/` | `~/.codex/`: config writable seed; prompts/rules/caveman prefs link/copy. Global instruction pointer added to existing `~/.codex/AGENTS.md`, not overwritten. No project trust/hook hashes. |
| D9 | `config/shell/bashrc.sh` | One source line at end of interactive Bash init; choose repo path. Resolve overlap with Omarchy completion/ble.sh/Starship hooks before enabling; do not append repeated hooks. |
| D10 | `config/shell/remove-silence.conf` | `$XDG_CONFIG_HOME/remove-silence.conf`: writable preference seed; live override preserved separately from script defaults. |
| D11 | `config/git/config` | Include from user's Git config after review; keep identity in local config, not repo. Existing identity untouched. Repo feature-branch policy takes precedence over generic init default. |
| D12 | `config/ghostty/config`, `config/yazi/` | Matching `$XDG_CONFIG_HOME/ghostty/config`, `$XDG_CONFIG_HOME/yazi/{yazi,keymap}.toml`: merge user prefs, do not replace native theme includes blindly. |
| D13 | `config/herdr/` | `$XDG_CONFIG_HOME/herdr/config.toml`: writable seed; `sounds/` copy/link. Resolve relative sound paths from app config dir on target. No onboarding/session state. |
| D14 | `bin/` | Direct links in `~/.local/bin` to each executable, preserve existing paths. **Never** install global executable named `notify-send`. `herdr-notify-send` additionally linked as `$XDG_DATA_HOME/dotfiles/herdr-notify/notify-send`; only `herdr-with-notify` prefixes that directory. |
| D15 | `config/browser/external-extensions/`, `extensions.tsv` | Reviewed Brave Origin external-extension manifests: normally `$XDG_CONFIG_HOME/BraveSoftware/Brave-Origin/External Extensions/`; verify current Origin data path. Apply to selected profiles if required by target mechanism. |
| D16 | `config/browser/managed-bookmarks.json` | Current Brave Origin managed-policy directory: inspect native package, normally system `/etc/brave/policies/managed/`. User executes privileged install; verify `brave://policy`. Keep native update policy. |
| D17 | `config/browser/bookmarks.xbel` | Sanitized public Synced seed for separate `~/config/bookmarks`/Floccus workflow; compare/import, never replace private bookmark tree. Separate repo remote not supplied. No watcher/publication implied. |
| D18 | `config/browser/launchers/`, `desktop/launchers/` | `$XDG_DATA_HOME/applications/`: native desktop entries; project HOME paths resolved by shell at runtime. Default suggested checkout names may need adaptation. Desktop `%` field codes require escaping for literal URL percent signs. |
| D19 | `config/kdenlive/kdenliverc` | `$XDG_CONFIG_HOME/kdenliverc`: seed declared keys only. Preserve live layout/recent files/language choices. `speech.vosk_folder_path` set to resolved `$XDG_DATA_HOME/kdenlive/speechmodels` during setup, not literal HOME token. |
| D20 | `services/` | `$XDG_CONFIG_HOME/systemd/user/`: rclone service/path + cptr service. Native templates use `%h`, `/usr/bin`, default rclone cfg path; render custom XDG path when needed. No activation during export. |
| D21 | `desktop/preferences.md` | Intent mapped to installed Omarchy/Hyprland user overrides, browser/app prefs, native firewall/SSH, peripheral/audio config. Never patch upstream shell/QML or copy old host IDs. System apply user-run. |
| D22 | `manifests/`, root `README.md`, root `AGENTS.md`, `docs/`, `.gitignore`, `scripts/`, `tests/` | Repo-owned source/validation/setup contracts. No runtime deployment except explicit tool/helper use. All mapped changes invoke `sync-config-aron` before/after batch. |

## Writable state boundary

Do not link mixed preference/state files directly into Git: apps can add private project paths, history, tokens, or trusted commands. Seed a writable destination, then reconcile only mapped portable keys. Before any replacement, inspect existing file/link and record backup path outside the repo. Preserve backups until the user verifies restoration; no cleanup to manufacture a clean worktree.

## Discovery / synchronization

- S1. Shared hub contains 22 skill entrypoints plus `_shared`/data; vendor system skills excluded. Current harnesses may natively discover `~/.agents/skills`; do not add duplicate links when that already works.
- S2. Pi supports configured skill paths; use one route to canonical hub. Old setup used `~/.pi/skills`; current runtime conventions must be inspected. Verify `/skill:sync-config-aron` or equivalent invocation plus one graphify entry in CLI discovery. Do not blindly assume folder name compatibility.
- S3. Mandatory M1–M4 invocation is agent instruction policy, not filesystem watcher. Manual/GUI changes require explicit reconciliation or next agent task. Skill code alone cannot observe GUI writes.
- S4. Origin URL, authoritative bootstrap branch, integration permissions, downstream effects remain **unset**. Initial export exception permits local creation only. Parent/user reviews before commits; no sync claim until remote equality + clean worktree evidence exists.
