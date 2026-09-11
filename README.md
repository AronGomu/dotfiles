# dotfiles

Portable personal config for native Omarchy. Full Neovim, Pi/Claude/Codex + shared skills, shell/dev/media tools, browser selections, selected desktop prefs, native user service templates. Plain files + agent instructions; no generic bootstrap framework.

## Start

- R1. Read [AGENTS.md](AGENTS.md), sole installer guide. Sources stay here; writable app state/auth stay outside Git.
- R2. User-authorized remote: existing `origin`, `AronGomu/dotfiles` on GitHub; bootstrap branch `main`. Fetch reviewed revision into preferred `~/config/dotfiles`; never replace existing checkout. Root guide owns sync, public-source review, and recovery policy.
- R3. Initial export was prepared on `bootstrap/dotfiles` for parent/user review, without staging or commits. Inspect Git for current lifecycle state; reviewed local staging/commits do not imply publication, installation, activation, or remote synchronization.
- R4. Offline checks: `PYTHONDONTWRITEBYTECODE=1 python3 scripts/validate.py` then `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v`.

| ID | Content | Reference |
|---|---|---|
| C1 | Native config + skill/media source | `config/`, `bin/`, `vendor/skills/` |
| C2 | Capabilities, workspace map, tested provenance | `manifests/tools.md`, `manifests/repos.tsv`, `manifests/sources.md` |
| C3 | Deployment ownership / writable seeds | `docs/deployment.md` |
| C4 | Validation / remaining target checks | `docs/validation.md` |
| C5 | Private state / permissions / license warnings | `docs/auth.md` |
| C6 | Personal desktop intent + native user units | `desktop/preferences.md`, `services/` |
| C7 | VPN-aware Tailscale launcher | `docs/tailscale-open.md` |

No boot/disk/OS framework, secrets/history, old OpenWhispr patches, bar auto-hide patch, grok-imagine, or DaVinci. Optional extra desktop prefs/troubleshooting stay opt-in. Independent Grok CLI remains supported.

Selected meme/sound assets retained locally. Redistribution rights need review; do not publish publicly before resolving license/privacy risks. Third-party snapshots retain available licenses; no blanket license imposed.
# dotfiles
