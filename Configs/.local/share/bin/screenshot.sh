#!/usr/bin/env sh

# Shader management with improved error handling
restore_shader() {
    if [ -n "$shader" ] && command -v hyprshade >/dev/null; then
        hyprshade on "$shader"
    fi
}

save_shader() {
    if command -v hyprshade >/dev/null; then
        shader=$(hyprshade current)
        hyprshade off
        trap restore_shader EXIT INT TERM
    fi
}

# Initialize paths and directories
XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
scrDir=$(dirname "$(realpath "$0")")
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
timestamp=$(date +'%Y-%m-%d_%H-%M-%S')
save_file="screenshot_${timestamp}.png"

# Ensure save directory exists
mkdir -p "$save_dir"

# Source global controls if exists
[ -f "$scrDir/globalcontrol.sh" ] && source "$scrDir/globalcontrol.sh"

# Save current shader state
save_shader

print_error() {
    echo "Usage: $(basename "$0") <action>
Actions:
    p  : capture full screen
    s  : select area/window
    sf : select area/window (frozen)
    m  : capture active monitor"
    exit 1
}

take_screenshot() {
    local mode=$1
    local path="${save_dir}/${save_file}"

    case $mode in
        p)  flameshot full -p "$path" ;;
        s|sf) flameshot gui -p "$path" ;;
        m)  flameshot screen -p "$path" ;;
        *)  print_error ;;
    esac

    # Check if screenshot was successful and notify
    if [ -f "$path" ]; then
        notify-send -a "Screenshot" -i "$path" "Screenshot saved" "Location: ${save_dir}"
        echo "Screenshot saved to: $path"
        return 0
    else
        notify-send -a "Screenshot" -u critical "Screenshot failed"
        return 1
    fi
}

# Execute screenshot command based on argument
take_screenshot "$1"