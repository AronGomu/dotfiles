---
description: Add URLs to portable web launchers, managed Brave bookmarks, reviewed Floccus export
argument-hint: "<url> [url…]"
---
Read shared `sync-config-aron` before edits. Resolve dotfiles owner through `AGENTS.md` + `docs/deployment.md`.

- P1. User URLs: $@. Missing URL → ask. Derive short title from site.
- P2. Privacy-review URL/title first. Never export message/thread IDs, private document links, auth query params, or personal labels. Generalize private messaging links to service inbox only with clear report.
- P3. Unless user narrows scope, update `config/browser/launchers/*.desktop`, `config/browser/managed-bookmarks.json` Daily folder, `config/browser/bookmarks.xbel` Synced folder. Use native desktop syntax; quote URL, escape literal `%` as `%%` in Exec.
- P4. Floccus runtime/local bookmark repo is separate. Compare before import; do not replace private bookmarks or invent remote. Publish separately only to authorized target after privacy review.
- P5. Run owner validation, invoke sync skill after batch. Report source changes separately from runtime policy reload/Floccus sync; never claim deployment without checks.
