# Path to your oh-my-zsh installation
export ZSH="/usr/share/oh-my-zsh"

# Set up Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname $ZINIT_HOME)" && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Load powerlevel10k theme
# source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# Function to load plugins
load_plugins() {
  # Load zsh-async
  zinit light mafredri/zsh-async

  # Load other plugins
  zinit light nullxception/roundy
  zinit snippet OMZ::plugins/git/git.plugin.zsh
  zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light chrissicool/zsh-256color
  zinit light Aloxaf/fzf-tab

  # Lazy-load oh-my-zsh
  zinit snippet OMZ::lib/completion.zsh
  zinit snippet OMZ::lib/history.zsh
  zinit snippet OMZ::lib/key-bindings.zsh
  zinit snippet OMZ::lib/theme-and-appearance.zsh
}

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Command not found handler
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]] ; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
    aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
    aurhelper="paru"
fi

# Package installation function
function in {
    local -a arch=() aur=()
    for pkg in "$@"; do
        if pacman -Si "${pkg}" &>/dev/null; then
            arch+=("${pkg}")
        else
            aur+=("${pkg}")
        fi
    done
    [[ ${#arch[@]} -gt 0 ]] && sudo pacman -S "${arch[@]}"
    [[ ${#aur[@]} -gt 0 ]] && ${aurhelper} -S "${aur[@]}"
}

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color'
alias c='clear'
alias vc='code'
alias mkdir='mkdir -p'

# Load p10k config if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add local bin to PATH
export PATH=$PATH:~/.local/bin
export PATH="$HOME/.cargo/bin:$PATH"

# Load plugins after Powerlevel10k instant prompt
load_plugins


export PATH=$PATH:/home/evrenos/.spicetify
