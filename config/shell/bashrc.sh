# shellcheck shell=bash
# Source once near end of interactive ~/.bashrc; preserve Omarchy-owned startup.
[[ $- == *i* ]] || return
[[ ${DOTFILES_BASH_LOADED:-} == 1 ]] && return
DOTFILES_BASH_LOADED=1

export EDITOR=nvim VISUAL=nvim TERMINAL=ghostty BROWSER=brave-origin
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export GROK_BASE_URL=https://api.x.ai/v1 GROK_MODEL=grok-4-latest
export OPENBW_MPQ_PATH="$HOME/Games/Starcraft"
for dir in "$HOME/.dotnet/tools" "$HOME/.local/bin"; do
  case ":$PATH:" in *":$dir:"*) ;; *) PATH="$dir:$PATH" ;; esac
done
export PATH
# Resolve native SDK location, never copy old loader/store paths.
if command -v dotnet >/dev/null 2>&1; then
  export DOTNET_ROOT
  DOTNET_ROOT=$(dirname -- "$(readlink -f -- "$(command -v dotnet)")")
fi

alias cat=bat
alias ll='eza -lah --group-directories-first'
alias v=nvim
alias lz=lazygit
alias gtbrain='cd "$HOME/brain"'
alias gtconfig='cd "$HOME/config"'
alias gtdotfiles='cd "$HOME/config/dotfiles"'
alias gtbookmarks='cd "$HOME/config/bookmarks"'
alias gtprojects='cd "$HOME/projects"'
alias gtascencio='cd "$HOME/projects/ascencio"'
alias gtessentia='cd "$HOME/projects/essentia"'
alias gtgones='cd "$HOME/projects/gones"'
alias gtmillions='cd "$HOME/projects/millions_must_die"'
alias brave-personal='brave-origin --profile-directory=Default'
alias brave-mtgones="brave-origin --profile-directory='Profile 1'"
alias herdr=herdr-with-notify

if [[ -f "$HOME/.pi/agent/configs/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$HOME/.pi/agent/configs/.env"
  set +a
fi
if [[ -n ${XAI_API_KEY:-} && -z ${GROK_API_KEY:-} ]]; then
  export GROK_API_KEY="$XAI_API_KEY"
fi
if [[ -n ${GROK_API_KEY:-} && -z ${XAI_API_KEY:-} ]]; then
  export XAI_API_KEY="$GROK_API_KEY"
fi

# Completion first, ble.sh deferred, Starship before final ble-attach.
if [[ -z ${BASH_COMPLETION_VERSINFO:-} && -f /usr/share/bash-completion/bash_completion ]]; then
  # shellcheck source=/dev/null
  . /usr/share/bash-completion/bash_completion
fi
if [[ -z ${BLE_VERSION:-} && -f /usr/share/blesh/ble.sh ]]; then
  # shellcheck source=/dev/null
  . /usr/share/blesh/ble.sh --noattach
fi
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Yazi shell integration: leave shell in directory selected by manager.
function y() {
  local tmp cwd
  tmp=$(mktemp -t 'yazi-cwd.XXXXXX') || return
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r cwd < "$tmp" || true
  if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return
  fi
  rm -f -- "$tmp"
}
[[ ${BLE_VERSION:-} ]] && ble-attach
