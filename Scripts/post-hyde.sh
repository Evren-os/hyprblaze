#!/usr/bin/env bash

#==============================================================================
# HyDE Advanced Setup Script for Arch Linux
# Author: Claude Systems Engineer
# Description: Professional-grade setup script for HyDE environment
#==============================================================================

#==============================================================================
# INITIALIZATION
#==============================================================================

set -euo pipefail  # Fail fast and safely

# Terminal colors
readonly RED=$'\e[1;31m'
readonly GREEN=$'\e[1;32m'
readonly BLUE=$'\e[1;34m'
readonly YELLOW=$'\e[1;33m'
readonly MAGENTA=$'\e[1;35m'
readonly NC=$'\e[0m'

# Critical paths
readonly HOME_DIR="$HOME"
readonly CLONE_DIR="$HOME_DIR/Clone"
readonly HYDE_DIR="$HOME_DIR/HyDE"
readonly CONFIG_DIR="$HOME_DIR/.config"
readonly HYDE_THEMES_DIR="$CLONE_DIR/hyde-themes"
readonly FONTS_SRC="$HYDE_DIR/Source/misc/fonts"
readonly FONTS_DEST="$HOME_DIR/.local/share/fonts"

# Configuration directories to process
readonly CONFIG_DIRS=("alacritty" "mpv" "hypr" "wezterm")

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

log() {
    local level="$1"
    local message="$2"
    local color

    case "$level" in
        "INFO") color="$BLUE";;
        "SUCCESS") color="$GREEN";;
        "WARNING") color="$YELLOW";;
        "ERROR") color="$RED";;
        *) color="$NC";;
    esac

    printf "${color}[%s]${NC} %s\n" "$level" "$message"
}

error_exit() {
    log "ERROR" "$1"
    exit 1
}

confirm_action() {
    local prompt="$1"
    local default="${2:-Y}"

    while true; do
        read -rp "$(printf "${MAGENTA}%s [Y/n]${NC} " "$prompt")" response
        case "${response:-$default}" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) log "WARNING" "Please answer yes or no.";;
        esac
    done
}

check_dependencies() {
    local deps=("git" "fc-cache")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error_exit "Required dependency not found: $dep"
        fi
    done
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log "INFO" "Creating directory: $dir"
        mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
    fi
}

#==============================================================================
# COMPONENT SETUP FUNCTIONS
#==============================================================================

setup_directories() {
    log "INFO" "Setting up required directories..."
    ensure_directory "$CLONE_DIR"
    ensure_directory "$CONFIG_DIR"
    ensure_directory "$FONTS_DEST"
}

clone_themes_repo() {
    if [[ ! -d "$HYDE_THEMES_DIR" ]]; then
        log "INFO" "Cloning hyde-themes repository..."
        git clone --depth 1 https://github.com/hyde-themes/hyde-themes.git "$HYDE_THEMES_DIR" ||
            error_exit "Failed to clone hyde-themes repository"
    else
        if confirm_action "hyde-themes repository already exists. Update it?"; then
            log "INFO" "Updating hyde-themes repository..."
            git -C "$HYDE_THEMES_DIR" pull || error_exit "Failed to update hyde-themes repository"
        fi
    fi
}

copy_configs() {
    log "INFO" "Copying configuration files..."
    for dir in "${CONFIG_DIRS[@]}"; do
        local source_dir="$HYDE_DIR/Configs/.config/$dir"
        local dest_dir="$CONFIG_DIR/$dir"

        if [[ -d "$source_dir" ]]; then
            log "INFO" "Processing $dir configuration..."
            if [[ -d "$dest_dir" ]]; then
                if confirm_action "Existing $dir config found. Override?"; then
                    rm -rf "$dest_dir"
                else
                    log "WARNING" "Skipping $dir configuration..."
                    continue
                fi
            fi
            cp -r "$source_dir" "$CONFIG_DIR/" || error_exit "Failed to copy $dir configuration"
            log "SUCCESS" "$dir configuration copied successfully"
        else
            log "WARNING" "$dir configuration not found in source"
        fi
    done
}

setup_sysfetch() {
    local sysfetch_source="$HYDE_DIR/Scripts/sysfetch"
    local sysfetch_dest="/usr/local/bin/sysfetch"

    if [[ -f "$sysfetch_source" ]]; then
        log "INFO" "Setting up sysfetch..."
        chmod +x "$sysfetch_source" || error_exit "Failed to make sysfetch executable"
        sudo ln -sf "$sysfetch_source" "$sysfetch_dest" || error_exit "Failed to create symbolic link for sysfetch"
        log "SUCCESS" "sysfetch setup completed"
    else
        error_exit "sysfetch script not found at $sysfetch_source"
    fi
}

process_wallpapers() {
    log "INFO" "Processing theme wallpapers..."
    local processed_count=0

    for theme_folder in "$HYDE_THEMES_DIR/themes"/*; do
        if [[ -d "$theme_folder" ]]; then
            local theme_name=$(basename "$theme_folder")
            local dest_wallpaper_dir="$CONFIG_DIR/hyde/themes/$theme_name/wallpapers"

            if [[ -d "$dest_wallpaper_dir" ]]; then
                if [[ -n "$(ls -A "$theme_folder")" ]]; then
                    log "INFO" "Processing wallpapers for theme: $theme_name"
                    while IFS= read -r -d '' file; do
                        if file "$file" | grep -qi "image"; then
                            cp -f "$file" "$dest_wallpaper_dir/" && ((processed_count++)) ||
                                log "WARNING" "Failed to copy wallpaper: $file"
                        fi
                    done < <(find "$theme_folder" -type f -print0)
                fi
            fi
        fi
    done

    log "SUCCESS" "Processed $processed_count wallpapers"
}

setup_fonts() {
    log "INFO" "Setting up fonts..."
    if [[ ! -d "$FONTS_SRC" ]]; then
        error_exit "Fonts source directory not found: $FONTS_SRC"
    fi

    cp -r "$FONTS_SRC"/* "$FONTS_DEST/" || error_exit "Failed to copy fonts"
    log "INFO" "Updating font cache..."
    fc-cache -fv || error_exit "Failed to update font cache"
    log "SUCCESS" "Fonts setup completed"
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================

main() {
    log "INFO" "Starting HyDE Advanced Setup..."

    # Check for required dependencies
    check_dependencies

    # Setup process
    setup_directories
    clone_themes_repo
    copy_configs
    setup_sysfetch
    process_wallpapers
    setup_fonts

    log "SUCCESS" "✨ HyDE setup completed successfully!"
    log "INFO" "You can now run 'sysfetch' from anywhere in the terminal."
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'error_exit "An unexpected error occurred. Exiting..."' ERR
    main "$@"
fi