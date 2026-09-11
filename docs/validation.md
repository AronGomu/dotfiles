# Validation contract

Root `AGENTS.md` owns setup. This document defines evidence, not a claim that target installation ran. Tested export snapshot/provenance: `manifests/sources.md`.

## Offline source checks

| ID | Command / check | Expected evidence |
|---|---|---|
| V1 | `PYTHONDONTWRITEBYTECODE=1 python3 scripts/validate.py` | JSON/TOML/XML/desktop parsing, desktop key-file escapes + Exec quote validation, Python AST, Bash syntax, required source coverage, shared skill names, executable flags, no source symlinks/old executable paths, local secret guard. Root `.pi-subagents/` generated orchestration artifacts excluded from deliverable checks only; secret guard unchanged. Exit 0. |
| V2 | `HERDR_BIN_PATH='' PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v` | Offline mock tests: helper paths/args, Herdr isolation, statusline, media defaults; ytmusic discovery failures before writes, retained playlists, unique backups/backup failure, symlink refusal; desktop escape rejection; proof runner exit 126/127. Scratch under repo `.tmp`, removed by tests. Native GLib checks parse all 41 launchers without launching apps; set `DOTFILES_TEST_GLIB` to an inspected native library path if automatic discovery fails. A skipped native check is not proof. |
| V3 | `bash -n` on every `.sh`/Bash entrypoint; `shellcheck` on changed native Bash helpers/config | No syntax errors; distinguish inherited lint from introduced failures. Do not execute shell init in live HOME to validate. |
| V4 | `node --experimental-strip-types --check` on each `config/pi/agent/extensions/**/*.ts` | Syntax-only check under Node 24; no extension import/execution or package/API compatibility proof. |
| V5 | `nvim --headless -u NONE -i NONE` with `loadfile` on each `config/nvim/**/*.lua` in isolated scratch HOME/XDG | Lua syntax only. Never load normal init during offline check: Lazy may fetch/install plugins. |
| V6 | `git diff --check`; `git diff --cached --check`; `git diff --cached --name-only`; `git status --porcelain=v1 --untracked-files=all` | No whitespace errors; record actual staged/untracked/HEAD state. Initial export was prepared unstaged on an unborn branch; later reviewed staging/commits are separate authorized steps. Empty unstaged diff does not validate untracked content; V1/V2 inspect it directly. No remote equality claim without configured remote proof. |
| V7 | `python3 scripts/secret_scan.py` | Redacted path/line/rule output only; 0 findings. Checks token/key/JWT/private-message URL patterns + private filenames. No general entropy/PII/license/media-content detection. |
| V8 | `gitleaks dir --no-banner --redact .` if supported by installed version (`gitleaks --help` first) | Full scanner report redacted, 0 unresolved findings. No fetched global install during export. Missing scanner is recorded, not silently claimed passed. Before publication install/review scanner through approved native route; review outgoing history/diff and binary media manually. |

## Tailscale launcher

- T1. Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_tailscale_open.py -v`. Mocked commands cover disconnect, failure, unknown tunnels, authenticated startup, browser login, missing dependency, and timeout. No live VPN/service/browser mutations.
- T2. Validate `desktop/launchers/tailscale-open.desktop` with V1/V2. Terminal must remain enabled; executable `bin/tailscale-open` must be on desktop PATH after deployment. Nix mirror script/test/doc must remain byte-identical.
- T3. After user deployment, invoke locally with informed VPN-disconnect consent. Check browser login if logged out, local tailnet IP on success, preserved firewall/DNS/security policy on failure. Live network/auth validation is separate from offline mocks; never store auth URLs as evidence.

## Pi remembered defaults

- P1. Run `node --experimental-vm-modules --test tests/pi-remember-model.mjs`. Pi must be importable; otherwise set `PI_TEST_PACKAGE_DIR` to inspected package root containing `dist/index.js`. Real SettingsManager, isolated scratch settings, mocked extension event context; no live config/API writes.
- P2. Expected: 8 tests pass, zero skipped. Covers model/thinking defaults read by fresh SettingsManager, rapid events, teardown drain, headless isolation, per-model override, unrelated/project settings, malformed JSON. Test alone does not prove deployed TUI behavior.
- P3. After user deployment: change model + thinking, `/new`, quit/restart plain `pi`; confirm last pair. Explicit CLI/project overrides still win. Details: `config/pi/agent/extensions/remember-model/README.md`.

## Media preservation checks

`ytmusic-sync` retains stale and unrelated `.m3u8` files, including with `--prune`.
That flag only moves orphaned audio; removed/renamed remote playlists no longer
trigger local playlist deletion. Discovery subprocess failures abort before
mutation, including partial stdout; stderr exposes only allowlisted diagnostics
(HTTP status or fixed connection errors), never raw credential-bearing output.

Changed named outputs get exclusive sibling `<name>.m3u8.ytmusic-sync-backup-N`
files before replacement. Backups preserve original bytes, use private permissions,
are flushed before writing the new content, and are never automatically removed.
Unchanged outputs are not rewritten; playlist symlinks are refused. To restore,
inspect the backup and current file, preserve the current file separately, then
copy the chosen backup to the original path only after approving replacement.
Backups/stale outputs accumulate until explicitly reviewed; no ownership system
or automatic cleanup is claimed. Existing download, audio-prune and Strawberry
DB behavior still requires disposable sample/runtime review.

## Inherited test-proof limitation

`config/agents/skills/make-max-test-aron/gates/prove-test.sh` now returns
`CANNOT RUN` (exit 2) for runner exits 126/127 instead of accepting them as
expected test failures. Offline regression stubs Git worktree operations and
runs missing/non-executable fixture runners; no commits or real worktrees needed.
This is not full gate certification: other infrastructure/import failures can
still count as proof. Agents must NOT rely on G11 PASS as automated proof until
separately repaired and validated; require independent red/green assertion
evidence. Gate architecture and complete disposable Git scenarios remain out of
this source-preservation fix pass.

## Required target checks — not offline source proof

- [ ] R1. Editor: `nvim --headless '+checkhealth' '+qa'` on deployed config, inspect diagnostic output. C#/Razor/Blazor Roslyn + completion, native .NET 10 build/test, breakpoint attach/start, DLL autopicker, scope walker, neotest-vstest nearest/file/debug flows. TS/Angular templates + HTML/CSS/Lua navigation/format. Verify original keymaps. **verify:** recorded project cmds/UI observations + final plugin lock diff.
- [ ] R2. Agents: Pi pinned packages/slop/models/custom extensions load; Herdr managed integration + blocked sidecar work; Claude/Codex sanitized prefs/statusline/docs MCP. Shared skill discovery one copy, graphify available, make-features alias delegates. Verify mandatory sync invocation before/after mapped edit. **verify:** startup logs reviewed without auth values, actual discovery/invocation results.
- [ ] R3. Shell/terminal/workspace: repeated source/deployment no duplicate hooks/PATH/skill links; ble.sh wraps Starship; plain direnv; Git identity untouched; Yazi edit/Escape/cwd; Ghostty Ctrl+Enter. Clone helper never updates existing real checkout. **verify:** shell/UI smoke checks + repo status before/after.
- [ ] R4. Media: all three scripts on sample copies; dependency/API/version compatibility, image dimensions/quality, retake tool project restore; ytmusic dry-run before downloads/DB ops. **verify:** generated output compared, originals unchanged, no paid API calls without approval.
- [ ] R5. Desktop: bar two presses hide/show; idle no hide; theme/cursor/scale/gaps/mouse/startup/workspaces/NightLight; normal OpenWhispr dictation/cancel/paste; Kdenlive/OBS/GIMP; VOSK FR/EN + turbo; browser profiles/five extensions/bookmarks/all launchers. **verify:** actual UI observations + current native config paths.
- [ ] R6. Services/security: native unit parse after path rendering; user-approved activation. Drive mount, cptr loopback only/umask, SSH/mosh allowed tailnet but denied LAN/WAN, Mullvad coexistence. Gaming/OneKey/FileExplorer/Razer/Bluetooth/audio as selected. **verify:** `ss -ltn`, interface firewall review/probes, unit status, app smoke checks without secrets.
- [ ] R7. Projects: `dotnet build`, `dotnet test`, relevant `npx playwright test`; `docker info` proves rootless where needed; Python venv imports Pillow/lxml/requests. **verify:** relevant project-specific output, no copied framework env flags.

## Sync skill scenario gate

Skill is agent procedure, not automated Git helper. Do not substitute string-presence tests for actual transaction evidence. Authoritative remote/branch now configured in root AGENTS.md; disposable local-repo exercise remains separate review/runtime gate. No claims these scenarios were executed during source export.

| ID | Disposable scenario | Required behavior |
|---|---|---|
| S1 | Clean/no change | No empty commit; fetch/verify bootstrap equality; clean + `0 0`. |
| S2 | Intentional mapped edit | Preflight baseline, validate/scan, exact staging, normal commit, authorized push/fetch equality. |
| S3 | Unrelated dirty file | Block sync; preserve file/status; no stash/reset/mass-stage. |
| S4 | Secret finding | Block before staging/publication; redact values. |
| S5 | Remote divergence | Block; no rewrite or force push. |
| S6 | Rejected push | Preserve commit; network retry once, auth/protection stop. |
| S7 | Feature-only delivery | Report pending bootstrap integration, never full sync. |
| S8 | Authorized reversible push | No redundant per-push confirmation after visibility/downstream/recovery checks. |
| S9 | Irreversible/unknown downstream effects | Stop before push, request decision; clean local commit not sufficient. |
| S10 | Initial bootstrap remote unset | Local creation/validation allowed; no invented origin, commit/push unasked, or false sync claim. |

## Limits

- L1. Static parsing is not runtime health. No app install, plugin restore, model download, paid API, service activation, firewall apply, public remote, or system mutation in initial export.
- L2. Pattern-only secret scan can miss secrets, personal data, metadata, binary content. License review is separate. Review full outgoing content/history before configuring public origin.
- L3. Native user unit templates assume standard Arch `/usr/bin` and default rclone cfg path. Resolve XDG overrides on target; source export host lacks native executables, so host `systemd-analyze verify` cannot prove target deployment readiness.
