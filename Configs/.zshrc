#############################################################
# Core ZSH Configuration
#############################################################

# Oh My Zsh Installation Path
export ZSH="/usr/share/oh-my-zsh"

# Initialize Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Path Configuration
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="$PATH:/home/evrenos/.spicetify"

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

#############################################################
# Package Management Functions
#############################################################

# Detect AUR Helper
if pacman -Qi yay &>/dev/null; then
    aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
    aurhelper="paru"
fi

# Smart Package Installation
in() {
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

#############################################################
# YouTube Download Functions
#############################################################

# Get Video Formats
get_video_formats() {
    local url=$1
    yt-dlp -F $url
}

# Enhanced YouTube Download Function
ytmax() {
    local quality=${1:-"max"}
    local url=$2

    # Handle URL-only input
    if [[ -z "$url" && "$quality" =~ ^https?:// ]]; then
        url=$quality
        quality="max"
    fi

    # Base Parameters
    local base_params=(
        "--format-sort" "filesize,res,vcodec:prores,vcodec:av01,vcodec:vp9.2,vcodec:vp9,acodec:flac,acodec:alac,acodec:wav,asr:max,abr:max,vbr:max,tbr:max"
        "--prefer-free-formats"
        "--format-sort-force"
        "--merge-output-format" "mkv"
        "--no-mtime"
    )

    local output_template="%(title)s [%(id)s][%(height)sp][vcodec-%(vcodec)s][acodec-%(acodec)s].%(ext)s"

    # Quality Presets
    local format_string
    case $quality in
        4k)    format_string="bv*[height<=2160][vcodec=prores]/bv*[height<=2160][vcodec=av01]+ba[acodec=flac]/bv*[height<=2160][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=2160]+ba/b[height<=2160]" ;;
        2k)    format_string="bv*[height<=1440][vcodec=prores]/bv*[height<=1440][vcodec=av01]+ba[acodec=flac]/bv*[height<=1440][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=1440]+ba/b[height<=1440]" ;;
        1080)  format_string="bv*[height<=1080][vcodec=prores]/bv*[height<=1080][vcodec=av01]+ba[acodec=flac]/bv*[height<=1080][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=1080]+ba/b[height<=1080]" ;;
        web)   format_string="bv*[vcodec=prores]/bv*[vcodec=av01]+ba[acodec=flac]/bv*[vcodec=vp9.2]+ba[acodec=flac]/bv*+ba/b/best" ;;
        *)     format_string="bv*[vcodec=prores]/bv*[vcodec=av01]+ba[acodec=flac]/bv*[vcodec=vp9.2]+ba[acodec=flac]/bv*+ba/b/best" ;;
    esac

    local -a command=(
        "yt-dlp"
        "--format" "$format_string"
        "--output" "$output_template"
        "--no-write-description"
        "--no-write-info-json"
        "--no-write-annotations"
        "--no-embed-subs"
        "--no-embed-metadata"
    )
    command+=("$base_params[@]" "$url")

    echo "Downloading with absolute maximum quality settings..."
    "${command[@]}"
}

# YouTube Help Function
ytmax_help() {
    echo "
YtMax Download Helper - Absolute Maximum Quality, No Extra Files
=================================================================

Commands:
- ytmax [url]            : Download maximum quality (ProRes/AV1 + FLAC)
- ytmax 4k [url]         : Download at 4K quality
- ytmax 2k [url]         : Download at 2K quality
- ytmax 1080 [url]       : Download at 1080p quality
- ytmax web [url]        : Download from non-YouTube sites
- ytf [url]              : Show available formats
- update-ytdlp           : Update yt-dlp

Examples:
ytmax https://youtube.com/watch?v=...
ytmax 4k https://youtube.com/watch?v=...
ytmax web https://vimeo.com/...
"
}

#############################################################
# Aliases
#############################################################

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color'
alias c='clear'
alias mkdir='mkdir -p'

# Applications
alias vc='code'
alias docker-start="sudo systemctl start docker"
alias docker-stop="sudo systemctl stop docker"

# System Updates
alias upchk="paru -Qua && checkupdates"
alias system-update="paru -Syu --noconfirm"

# YouTube Downloads
alias yt='ytmax'
alias ytf='get_video_formats'
alias update-ytdlp='yt-dlp -U'
alias ythelp='ytmax_help'

#############################################################
# Theme and Appearance
#############################################################

# Initialize Oh My Posh
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# System Information Display
turbofetch

#############################################################
# Additional Tools Configuration
#############################################################

# start_time=$(date +%s%3N)  # Milliseconds precision
# rufet
# end_time=$(date +%s%3N)
# echo "Startup time with fetch tool: $((end_time - start_time)) ms" >> ~/fetch_startup_time.log

# Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/home/evrenos/.bun/_bun" ] && source "/home/evrenos/.bun/_bun"
