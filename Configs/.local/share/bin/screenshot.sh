#!/usr/bin/env sh

# Shader management with improved error handling
restore_shader() {
    if [ -n "$shader" ] && command -v hyprshade >/dev/null 2>&1; then
        hyprshade on "$shader"
    fi
}

save_shader() {
    if command -v hyprshade >/dev/null 2>&1; then
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
save_path="${save_dir}/${save_file}"

# Ensure save directory exists
mkdir -p "$save_dir" || { echo "Failed to create save directory: $save_dir"; exit 1; }

# Source global controls if exists
[ -f "$scrDir/globalcontrol.sh" ] && . "$scrDir/globalcontrol.sh"

# Save current shader state
save_shader

# Print usage and error
print_usage() {
    cat <<EOF
Usage: $(basename "$0") <action>
Actions:
    p  : Capture full screen
    s  : Select area/window
    sf : Select area/window (frozen)
    m  : Capture active monitor
EOF
    exit 1
}

# Copy image to clipboard
copy_to_clipboard() {
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$1"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -t image/png -i "$1"
    else
        notify-send -a "Screenshot" -u critical "Clipboard copy failed" "Install 'wl-copy' (Wayland) or 'xclip' (X11) for clipboard functionality."
        return 1
    fi
    notify-send -a "Screenshot" "Screenshot copied to clipboard"
}

# Take screenshot based on mode
take_screenshot() {
    local mode=$1

    case $mode in
        p)  flameshot full -p "$save_path" ;;
        s)  flameshot gui -p "$save_path" ;;
        sf) flameshot gui -p "$save_path" ;;  # Frozen mode handled the same as `s` by Flameshot
        m)  flameshot screen -p "$save_path" ;;
        *)  print_usage ;;
    esac

    # Verify if screenshot succeeded
    if [ -f "$save_path" ]; then
        notify-send -a "Screenshot" -i "$save_path" "Screenshot saved" "Location: ${save_dir}"
        echo "Screenshot saved to: $save_path"
        copy_to_clipboard "$save_path"
    else
        notify-send -a "Screenshot" -u critical "Screenshot failed"
        exit 1
    fi
}

# Execute based on argument
[ "$#" -eq 1 ] || print_usage
take_screenshot "$1"
