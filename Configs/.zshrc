#############################################################
# Core ZSH Configuration
#############################################################
export ZSH="/usr/share/oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Path Configuration
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="$PATH:/home/evrenos/.spicetify"

# Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Starship Configuration
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export STARSHIP_CACHE="$HOME/.cache/starship"
eval "$(starship init zsh)"

#############################################################
# Zinit Plugin Manager Setup
#############################################################

# Initialize Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname $ZINIT_HOME)" && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Load Essential Plugins
zinit light mafredri/zsh-async
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light chrissicool/zsh-256color
zinit light Aloxaf/fzf-tab

#############################################################
# Package Management
#############################################################
# Detect AUR Helper
if (( $+commands[paru] )); then
    aurhelper="paru"
elif (( $+commands[yay] )); then
    aurhelper="yay"
fi

# Check Updates
function check_updates() {
    local official_updates=$(paru -Quq --repo | wc -l)
    local aur_updates=$(paru -Quq --aur | wc -l)

    if [[ $official_updates -eq 0 && $aur_updates -eq 0 ]]; then
        print -P "%F{blue}AUR n Official? Dead AF, no updates, bruh.%f"
    else
        if [[ $official_updates -gt 0 ]]; then
            print -P "%F{green}Official Updates:%f $official_updates available"
            paru -Qu --repo
        else
            print -P "%F{blue}Official updates? Nada, dipped out.%f"
        fi

        if [[ $aur_updates -gt 0 ]]; then
            print -P "%F{yellow}AUR Updates:%f $aur_updates available"
            paru -Qu --aur
        else
            print -P "%F{blue}AUR's a ghost, no update juice here.%f"
        fi
    fi
}

#############################################################
# YouTube Download Functions
#############################################################
YT_OPTS=(
    --format-sort "res,fps,vcodec:av01,vcodec:vp9.2,vcodec:vp9,acodec:opus"
    --prefer-free-formats
    --format-sort-force
    --merge-output-format "mkv"
    --concurrent-fragments 3
    --no-mtime
    --output "%(title)s [%(id)s][%(height)sp][%(fps)sfps][%(vcodec)s][%(acodec)s].%(ext)s"
)

function ytmax() {
    local quality=${1:-"max"}
    local url=$2

    if [[ -z "$url" && "$quality" =~ ^https?:// ]]; then
        url=$quality
        quality="max"
    fi

    local format_string
    case $quality in
        4k)    format_string="bv*[height<=2160][vcodec^=av01]+ba[acodec=opus]/bv*[height<=2160][vcodec^=vp9]+ba/bv*[height<=2160]+ba" ;;
        2k)    format_string="bv*[height<=1440][vcodec^=av01]+ba[acodec=opus]/bv*[height<=1440][vcodec^=vp9]+ba/bv*[height<=1440]+ba" ;;
        1080)  format_string="bv*[height<=1080][vcodec^=av01]+ba[acodec=opus]/bv*[height<=1080][vcodec^=vp9]+ba/bv*[height<=1080]+ba" ;;
        *)     format_string="bv*[vcodec^=av01]+ba[acodec=opus]/bv*[vcodec^=vp9]+ba/bv*+ba/b" ;;
    esac

    yt-dlp ${YT_OPTS[@]} --format "$format_string" "$url"
}

function yt-batch() {
    print -P "%F{blue}Enter video URLs (separated by commas). Press [ENTER] when done:%f"
    read -r urls

    local failed_urls=()
    local IFS=','

    for url in ${=urls}; do
        url=${url## }  # Remove leading spaces
        url=${url%% }  # Remove trailing spaces

        print -P "\n%F{yellow}Downloading: $url%f"
        if ! ytmax "$url"; then
            failed_urls+=("$url")
            print -P "%F{red}Failed to download: $url%f"
        fi
    done

    if (( ${#failed_urls[@]} > 0 )); then
        print -P "\n%F{red}Failed URLs:%f"
        printf '%s\n' "${failed_urls[@]}"
    fi
}

#############################################################
# Aliases
#############################################################
# Navigation & Basic
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color=auto'
alias mkdir='mkdir -p'
alias c='clear'

# System Management
alias docker-start='sudo systemctl start docker'
alias docker-stop='sudo systemctl stop docker'
alias upchk='check_updates'

# Applications
alias code='codium'

# Media Download
alias yt='ytmax'
alias ytf='yt-dlp -F'
alias ytb='yt-batch'

#############################################################
# Theme and Appearance
#############################################################
rustor