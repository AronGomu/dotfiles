# Private state / permission review

Installer entrypoint: root `AGENTS.md`. This repo contains portable preference seeds, not an account or disaster-recovery backup.

## Never export

- S1. API keys, OAuth/browser sessions, SSH private keys, wallet recovery material, password DBs, cookies, credential stores, rclone.conf, agent auth/trust/history/sessions, cptr private app data, recordings/transcripts, model caches.
- S2. Old project trust paths, trusted hook hashes, personal reminder text, browser private thread/document URLs, contacts, private bookmark metadata. Git identity is deliberately omitted; configure locally.
- S3. Do not use ignore rules as proof of safety. Review all outgoing commits/diffs and untracked paths before publication. Initial local scanner is pattern-only; see `docs/validation.md` for limits.

## Recovery by service

| ID | Service | Private recovery action |
|---|---|---|
| A1 | GitHub / project remotes | User supplies authorized remote, branch, visibility; authenticate via `gh auth login` or fresh SSH key enrollment. Never infer remote ownership from CLI login. Do not export key material or print credential-bearing URLs. |
| A2 | Pi / Claude / Codex | Use each current CLI's supported login/model-provider setup. Private files stay in app runtime dirs. For API-key workflows, manually copy `config/pi/agent/configs/env.example` to `~/.pi/agent/configs/.env`, fill values privately, restrict permissions to 600. Never run `cat`, `printenv`, or logs that reveal filled values. |
| A3 | Herdr | Re-onboard normal app; config omits onboarding state. Herdr integration communicates over current app-provided local socket, not fixed machine path. Notification titles/body may reveal project names to desktop notification history; review local privacy settings. |
| A4 | Brave Origin / Floccus | Re-authenticate two profiles separately; import only reviewed public XBEL seed. Local export retained all 21 bookmark entries; one private Messenger thread became generic inbox. Original timestamps/IDs/custom labels stripped. Separate bookmark repo remains private/local until user configures remote. Do not upload original browser profile. |
| A5 | rclone Google Drive | Run normal `rclone config` interactively outside repo, name remote `gdrive`. OAuth config remains `$XDG_CONFIG_HOME/rclone/rclone.conf`, permission 600. Confirm chosen account privately; inspect mount target before activation. |
| A6 | Tailscale / Mullvad | Re-enroll host/account via official apps. No stored auth keys/account numbers. Tailnet SSH/mosh firewall contract in `desktop/preferences.md`; do not activate inbound services before verification. |
| A7 | cptr | Login through current app flow after localhost-only service setup. Keep `~/.cptr` private (`0077` service umask). Never expose port 8000 via wildcard bind, router, or public tunnel as config shortcut. |
| A8 | OneKey / KeePassXC | Restore separately from verified encrypted backup. No seed words, private keys, wallet DBs, password databases, recovery codes in Git. |

## Retained permissions are not automatic authorization

Claude seed preserves source preferences `permissions.defaultMode=auto`, `skipDangerousModePermissionPrompt=true`, `skipAutoPermissionPrompt=true`, and `useAutoModeDuringPlan=true`. These reduce confirmation prompts. Review them explicitly before deployment; omit or tighten locally if user does not authorize that behavior. Claude bridge retains `allowFullMode=true` and `defaultIsolated=false`; inspect its capabilities before enabling. Codex keeps `approval_policy=on-request` but source allow-rules for `curl`, `yt-dlp`, dev/test commands, local HTTP server, and MCP config remain broad. Rules are preferences, not permission to publish, spend, leak data, erase user files, or apply system changes. Global safeguards still win.

Pi permission gate uses only four regex patterns (sudo, chmod/chown 777, printenv, bare env), with non-UI blocking enabled. It is not a shell sandbox and does not detect every destructive command. Keep normal tool protections enabled; review package extension exclusions and trusted configs on target.

## Script / asset safety

- R1. Inherited `social-square` uses `mv` onto output and can overwrite existing output. Choose fresh path on sample copies; explicit approval required for irreversible replacement. `remove-silence` preserves occupied normal paths through suffixing, but source helper has not been hardened against every symlink/race case. Do not use either against irreplaceable originals without backup.
- R2. `ytmusic-sync --dry-run` contacts public services; no local mutations. Normal mode downloads/rebuilds playlists, --prune moves orphan tracks to recoverable trash, --relink rewrites Strawberry DB after backup and refuses while app runs. User must review effects; no automatic destructive media/DB testing during export.
- R3. Selected meme videos and Herdr sound files retained as requested. Redistribution rights/provenance not established; do not publish publicly until owner/license/privacy review resolves rights. Vendor snapshots retain available licenses; missing per-skill licenses are noted in source manifest. No blanket license imposed.
- R4. Encrypted backups of original notes/auth/bookmarks/project work remain user task. This export does not prove restore readiness or authorize retiring any disk.
