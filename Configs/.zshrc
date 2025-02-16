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
    # Ensure checkupdates exists
    if ! command -v checkupdates >/dev/null 2>&1; then
        print -P "%F{red}checkupdates is MIA. Install 'pacman-contrib' or rot.%f"
        return 1
    fi

    # Use the provided AUR helper if set; otherwise default to 'paru'
    if [ -z "${aur_helper}" ]; then
        aur_helper="paru"
    fi
    if ! command -v "${aur_helper}" >/dev/null 2>&1; then
        print -P "%F{red}${aur_helper} is missing. Please install it or adjust your aur_helper variable.%f"
        return 1
    fi

    ### Database Sync (if needed) ###
    local db_sync_needed=false
    if [[ $(find /var/lib/pacman/sync/ -type f -mtime +1 2>/dev/null) ]]; then
        db_sync_needed=true
    fi

    if $db_sync_needed; then
        sudo pacman -Sy --quiet --noconfirm >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            print -P "%F{red}Sync failed. Internet’s dead or mirrors hate you.%f"
            return 1
        fi
    fi

    ### Fetch Updates ###
    # Official updates from pacman repositories
    local official_updates
    official_updates=$(checkupdates 2>/dev/null)

    # Non-official updates: from AUR
    local non_official_updates=""
    # AUR helper output – apply the sed/grep pipeline from update-check.sh
    if [ -n "${aur_helper}" ]; then
        local aur_output
        aur_output=$("${aur_helper}" -Qua 2>/dev/null | \
            sed 's/^ *//' | sed 's/ \+/ /g' | grep -vw "\[ignored\]$")
        non_official_updates="${aur_output}"
    fi

    # If no_version is set, strip version details so only package names remain
    if [ -n "${no_version}" ]; then
        official_updates=$(echo "${official_updates}" | awk '{print $1}')
        if [ -n "$non_official_updates" ]; then
            non_official_updates=$(echo "${non_official_updates}" | awk '{print $1}')
        fi
    fi

    ### Display Results ###
    if [[ -z "$official_updates" && -z "$non_official_updates" ]]; then
        print -P "%F{blue}No updates. Your system mocks entropy.%f"
    else
        # Official updates block
        if [[ -n "$official_updates" ]]; then
            local official_count
            official_count=$(echo "$official_updates" | wc -l | tr -d ' ')
            print -P "%F{green}${official_count} official updates. The grind never stops.%f"
            print "$official_updates"
        else
            print -P "%F{blue}Official repos: barren.%f"
        fi

        # Determine label for non-official updates based on what’s enabled
        if [ -n "${aur_helper}" ] && [ -n "${flatpak_support}" ]; then
            local non_official_label="AUR/Flatpak updates. They’re watching."
        elif [ -n "${aur_helper}" ]; then
            local non_official_label="AUR updates. They’re watching."
        elif [ -n "${flatpak_support}" ]; then
            local non_official_label="Flatpak updates. They’re watching."
        fi

        # Non-official updates block
        if [[ -n "$non_official_updates" ]]; then
            local non_official_count
            non_official_count=$(echo "$non_official_updates" | wc -l | tr -d ' ')
            print -P "%F{yellow}${non_official_count} ${non_official_label}%f"
            print "$non_official_updates"
        else
            if [ -n "${aur_helper}" ] && [ -n "${flatpak_support}" ]; then
                print -P "%F{blue}AUR/Flatpak sleeps. Silence is deadly.%f"
            elif [ -n "${aur_helper}" ]; then
                print -P "%F{blue}AUR sleeps. Silence is deadly.%f"
            elif [ -n "${flatpak_support}" ]; then
                print -P "%F{blue}Flatpak sleeps. Silence is deadly.%f"
            fi
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