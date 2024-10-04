# Constants
export ZSH="/usr/share/oh-my-zsh"
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# PATH modifications
typeset -U path  # Ensure unique entries
path+=("$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.spicetify")
export PATH

# Zinit initialization
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Plugin loading function
function load_plugins() {
  # Critical plugins - load immediately and in order
  zinit light mafredri/zsh-async
  zinit light nullxception/roundy
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting

  # Oh-My-Zsh libraries - load immediately for consistent behavior
  zinit snippet OMZ::lib/completion.zsh
  zinit snippet OMZ::lib/history.zsh
  zinit snippet OMZ::lib/key-bindings.zsh
  zinit snippet OMZ::lib/theme-and-appearance.zsh

  # Oh-My-Zsh plugins - load immediately
  zinit snippet OMZ::plugins/git/git.plugin.zsh
  zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

  # Feature plugins - can be loaded with slight delay
  zinit ice wait'0' lucid
  zinit light chrissicool/zsh-256color

  zinit ice wait'0' lucid
  zinit light Aloxaf/fzf-tab
}

# Package management
function detect_aur_helper() {
  for helper in yay paru; do
    if command -v $helper >/dev/null; then
      echo $helper
      return 0
    fi
  done
  return 1
}

AUR_HELPER=$(detect_aur_helper)

function in() {
  local -a arch=() aur=()
  for pkg in "$@"; do
    if pacman -Si "${pkg}" &>/dev/null; then
      arch+=("${pkg}")
    else
      aur+=("${pkg}")
    fi
  done
  [[ ${#arch[@]} -gt 0 ]] && sudo pacman -S "${arch[@]}"
  [[ ${#aur[@]} -gt 0 && -n "$AUR_HELPER" ]] && $AUR_HELPER -S "${aur[@]}"
}

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color'
alias c='clear'
alias vc='code'
alias mkdir='mkdir -p'
alias pacman-update='sudo pacman -Syu --noconfirm'
alias system-update='sudo pacman -Syu --noconfirm && ${AUR_HELPER:+$AUR_HELPER -Syu --noconfirm}'

# Command not found handler
function command_not_found_handler() {
  local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
  printf 'zsh: command not found: %s\n' "$1"
  local pkg last_pkg=""
  for entry in "${entries[@]}"; do
    local fields=( ${(0)entry} )
    if [[ "$last_pkg" != "${fields[2]}" ]]; then
      printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
      last_pkg="${fields[2]}"
    fi
    printf '    /%s\n' "${fields[4]}"
  done
}

# Source Oh-My-Zsh before loading plugins
source $ZSH/oh-my-zsh.sh

# Load plugins
load_plugins

# Ensure plugins are working by initializing their features
# You can remove these lines after confirming everything works
autoload -Uz compinit && compinit  # Ensure completion is working
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)  # Ensure syntax highlighting is working