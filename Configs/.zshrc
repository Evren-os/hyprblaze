# Path to your oh-my-zsh installation
export ZSH="/usr/share/oh-my-zsh"

# Set up Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname $ZINIT_HOME)" && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Function to get available video formats
get_video_formats() {
    local url=$1
    yt-dlp -F $url
}

# Main function for downloading videos with absolute maximum quality, no extra files
ytmax() {
    local quality=${1:-"max"}
    local url=$2

    # Detect if only URL is provided, defaults to max quality
    if [[ -z "$url" && "$quality" =~ ^https?:// ]]; then
        url=$quality
        quality="max"
    fi

    # Base parameters with metadata download disabled
    local base_params=(
        "--format-sort" "filesize,res,vcodec:prores,vcodec:av01,vcodec:vp9.2,vcodec:vp9,acodec:flac,acodec:alac,acodec:wav,asr:max,abr:max,vbr:max,tbr:max"
        "--prefer-free-formats"
        "--format-sort-force"
        "--merge-output-format" "mkv"
        "--no-mtime"
    )

    # Minimal output template to avoid folders and extra files
    local output_template="%(title)s [%(id)s][%(height)sp][vcodec-%(vcodec)s][acodec-%(acodec)s].%(ext)s"

    # Define format strings for quality presets
    local format_string
    case $quality in
        4k)
            format_string="bv*[height<=2160][vcodec=prores]/bv*[height<=2160][vcodec=av01]+ba[acodec=flac]/bv*[height<=2160][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=2160]+ba/b[height<=2160]"
            ;;
        2k)
            format_string="bv*[height<=1440][vcodec=prores]/bv*[height<=1440][vcodec=av01]+ba[acodec=flac]/bv*[height<=1440][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=1440]+ba/b[height<=1440]"
            ;;
        1080)
            format_string="bv*[height<=1080][vcodec=prores]/bv*[height<=1080][vcodec=av01]+ba[acodec=flac]/bv*[height<=1080][vcodec=vp9.2]+ba[acodec=flac]/bv*[height<=1080]+ba/b[height<=1080]"
            ;;
        web)
            # Generic format selection for non-YouTube sites
            format_string="bv*[vcodec=prores]/bv*[vcodec=av01]+ba[acodec=flac]/bv*[vcodec=vp9.2]+ba[acodec=flac]/bv*+ba/b/best"
            ;;
        *)
            # Absolute maximum quality without resolution restrictions
            format_string="bv*[vcodec=prores]/bv*[vcodec=av01]+ba[acodec=flac]/bv*[vcodec=vp9.2]+ba[acodec=flac]/bv*+ba/b/best"
            ;;
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

# Aliases
alias yt='ytmax'
alias ytf='get_video_formats'
alias update-ytdlp='yt-dlp -U'
alias ythelp='ytmax_help'

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

# Load Zinit plugins
load_plugins() {
    zinit light mafredri/zsh-async
    zinit light nullxception/roundy
    zinit snippet OMZ::plugins/git/git.plugin.zsh
    zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
    zinit light zsh-users/zsh-autosuggestions
    zinit light zsh-users/zsh-syntax-highlighting
    zinit light chrissicool/zsh-256color
    zinit light Aloxaf/fzf-tab
    zinit snippet OMZ::lib/completion.zsh
    zinit snippet OMZ::lib/history.zsh
    zinit snippet OMZ::lib/key-bindings.zsh
    zinit snippet OMZ::lib/theme-and-appearance.zsh
}

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Load plugins after Powerlevel10k instant prompt
load_plugins

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
    aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
    aurhelper="paru"
fi

# Package installation function
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

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color'
alias c='clear'
alias vc='code'
alias mkdir='mkdir -p'

# Update Aliases
alias upchk="paru -Qua && checkupdates"
alias system-update="paru -Syu --noconfirm"

# Load p10k config if it exists
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Add local bin to PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Add Spicetify to PATH
export PATH="$PATH:/home/evrenos/.spicetify"

fastfetch
