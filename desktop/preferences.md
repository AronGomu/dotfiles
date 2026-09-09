# Personal desktop intent

Native Omarchy owns upstream defaults, updates, drivers, shell implementation. Installer translates these deltas to installed Hyprland/bar schema; no copied Omarchy fork. Setup order: root `AGENTS.md`.

| ID | Required delta | Acceptance |
|---|---|---|
| O1a | Monitor scale 1; matching GTK/XWayland scale 1. Detect current outputs; no saved device IDs. | Text/app geometry consistent across outputs. |
| O1b | Mouse sensitivity `0.3`; inner gaps `2` px. Preserve other native defaults. | Inspect effective input/layout settings. |
| O1c | Ghostty app class `com.mitchellh.ghostty` or `ghostty` → workspace 1; Brave Origin → workspace 2. Start terminal, Brave Origin new window, normal OpenWhispr. Focus workspace 1 after startup settles (old delay 3s). | One instance per app on login; correct workspaces/final focus. |
| O1d | Tokyo Night theme. Adwaita cursor, size 24, GTK + XWayland. | Native theme tool applies user theme; cursor matches. |
| O1e | NightLight indicator always visible when supported. Preserve system-update widget/native provisioning. | Indicator visible; native updates remain available. |
| O1f | `Super+Shift+B` manually hides/shows bar using installed supported bar-control command/IPC. Resolve existing shortcut conflict explicitly. No idle timer, edge trigger, old QML patch. | Two presses hide/show; idle never hides bar. |
| O2 | Current normal OpenWhispr. Prefer `Ctrl+Space` toggle; Escape cancel through app's supported shortcut setup. No legacy D-Bus bindings, AppImage patches, forced socket, sg wrapper. | Dictation/cancel/paste work without stuck modifiers; test normal text app. |
| O4 | Normal Kdenlive, OBS Studio, GIMP. BreezeDark Kdenlive; VOSK FR/EN + Whisper turbo preferences. No DaVinci. | Apps launch; speech models discovered after separate download. |
| O5 | Brave Origin, personal `Default`, MTGones `Profile 1`; full extension/launcher/bookmark selections in `config/browser/`. | Both profile shortcuts open intended profile; five extensions present; public launchers work. |
| O7 | `gdrive:` → `~/GoogleDrive`, FUSE3, writes VFS cache, 1h dir/attribute caches; path/service units. | Re-authenticated Drive mount works as user. |
| O8 | Tailscale + key-only non-root OpenSSH + mosh; Mullvad app/CLI. | Tailnet access works; LAN/WAN inbound SSH/mosh blocked; VPN coexistence checked. |
| O9 | Open WebUI Computer `cptr`, loopback `127.0.0.1:8000`, umask `0077`, private `~/.cptr`. | `ss -ltn` shows no wildcard bind; data never in Git. |
| O10a | FileExplorer from `https://github.com/conaticus/FileExplorer`; current native source build, project lockfiles authoritative. OneKey Wallet from official signed release. | Normal launch; secrets/game/project data excluded. |
| O10b | Steam desktop only, Lutris, WoW64-capable Wine, winetricks, gamescope. No gamescope login session. Steam remote-play/server/LAN-transfer firewall openings disabled. | Local game launch; no added public listener rules. |
| O10c | Brood War 1.16.1 at `~/Games/Starcraft`; Wine prefix `~/Games/prefixes/starcraft`, `WINEDLLOVERRIDES=mscoree,mshtml=`, gamescope 640×480 → 1920×1080 fullscreen. | Aspect-correct launch using separately restored legal game data. |
| O10d | OpenBW/BWAPI project `~/projects/openbw-env/run.sh`; `OPENBW_MPQ_PATH=$HOME/Games/Starcraft`. Keep terminal diagnostics. | Engine/bot launch; project source restored separately. |
| O10e | OpenRazer, Polychromatic, razer-cli; Bluetooth enabled + Blueman; ddcutil/i2c brightness capability. Grants/groups based on current user/devices only. | Peripheral control, pairing, brightness work without copied device IDs. |
| O10f | PipeWire ALSA/Pulse/JACK + 32-bit audio support. Prefer onboard Realtek over HDMI (session/driver priority 2000 vs 100). Samson Q2U input-only `input:analog-stereo`, never default playback. | Correct default sink/mic; Wine audio works. |
| O10g | Old ALC897 jack detection failed; `pro-audio` profile worked. Reproduce on target before applying matched-device override; do not copy PCI IDs. | Playback routes correct; no blanket override on new hardware. |

## Optional only

- P1. O6: MIME defaults, Dolphin dimensions/tooltips, GTK/Qt dark prefs (Noto Sans 10/Breeze), terminal chooser, file-manager bookmarks, Obsidian, Thunderbird, CopyQ, KeePassXC. Ask before importing additional prefs; existing Omarchy defaults win otherwise.
- P2. O11: old monitor-hotplug, portal, cursor, OpenWhispr troubleshooting. Do not install old workarounds. Record new symptoms/repro before adaptation. FileExplorer `WEBKIT_DISABLE_DMABUF_RENDERER=1` only if renderer issue reproduced.

## Remote-access security boundary

Do not enable SSH or mosh until the target firewall is configured and verified. Allow TCP 22 and UDP 60000–61000 only on `tailscale0`; deny those ports on every other interface. Allow Tailscale's configured UDP transport separately. Use `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`. Existing authorized keys must be enrolled privately, not copied into this repo. Check reverse-path filtering compatibility and Mullvad LAN/tailnet routing without broadening inbound exposure. Do not activate a firewall remotely without a verified recovery path. User executes privileged package, firewall, daemon, and group changes.

## Assumptions

- A1. Fresh native Omarchy version unknown; bar control/Hyprland syntax resolved on target, not guessed in executable config.
- A2. Project source, wallet data, MPQ archives, model weights are external user/upstream assets; repo preserves prefs/install references only.
