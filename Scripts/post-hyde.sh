#!/bin/zsh

# Exit on error
set -e

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Paths
HYDE_CONFIG_DIR="$HOME/HyDE/Configs"
HYDE_SCRIPTS_DIR="$HOME/HyDE/Scripts"
CLONE_DIR="$HOME/Clone"
CONFIG_DIR="$HOME/.config"
THEMES_SOURCE_DIR="$CLONE_DIR/hyde-themes"
THEMES_DEST_DIR="$CONFIG_DIR/hyde/themes"

# Utility functions
print_color() {
    printf "${1}${2}${NC}\n"
}

info() { print_color "$BLUE" "[INFO] $1"; }
success() { print_color "$GREEN" "[SUCCESS] $1"; }
warning() { print_color "$YELLOW" "[WARNING] $1"; }
error() { print_color "$RED" "[ERROR] $1"; exit 1; }
confirm() {
    read -q "REPLY?${1} (y/N): "
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]]
}
ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1" || error "Failed to create directory: $1"
}

# Core functions
copy_config_files() {
    info "Copying configuration files..."

    # Check if source directory exists
    [[ -d "$HYDE_CONFIG_DIR/.config" ]] || error "Source config directory not found: $HYDE_CONFIG_DIR/.config"

    # Ensure destination directory exists
    mkdir -p "$CONFIG_DIR"

    # Use rsync for comprehensive file/directory copying
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -v: verbose output
    # --delete: remove files in destination not in source
    # --backup: create backups of existing files
    # --backup-dir: specify backup directory
    rsync -av \
          --delete \
          --backup \
          --backup-dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)" \
          "$HYDE_CONFIG_DIR/.config/" "$CONFIG_DIR/" || \
        error "Failed to copy configuration files"

    success "All configuration files copied successfully"
}

setup_zsh_config() {
    info "Setting up Zsh configuration..."

    local zshrc_source="$HYDE_CONFIG_DIR/.zshrc"
    [[ -f "$zshrc_source" ]] || error ".zshrc not found in $HYDE_CONFIG_DIR"

    cp -f "$zshrc_source" "$HOME/.zshrc" || error "Failed to copy .zshrc"
    source "$HOME/.zshrc" || warning "Failed to source .zshrc"
    success "Zsh configuration updated"
}

setup_grub_theme() {
    confirm "Would you like to set up the GRUB theme?" || return 0

    local grub_themes_dir="$CLONE_DIR/grub2-themes"

    if [[ ! -d "$grub_themes_dir" ]]; then
        git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git "$grub_themes_dir" ||
            error "Failed to clone GRUB themes repository"
    fi

    cd "$grub_themes_dir" || error "Failed to change to GRUB themes directory"
    if confirm "Would you like to edit the GRUB configuration file?"; then
        sudo nano /etc/default/grub
    fi
    sudo ./install.sh -t whitesur -i whitesur || error "Failed to install GRUB theme"
    success "GRUB theme installed"
}

setup_sysfetch() {
    info "Setting up sysfetch..."

    local sysfetch_path="$HYDE_SCRIPTS_DIR/sysfetch"
    [[ -f "$sysfetch_path" ]] || error "sysfetch script not found in $HYDE_SCRIPTS_DIR"

    chmod +x "$sysfetch_path" || error "Failed to make sysfetch executable"
    sudo ln -sf "$sysfetch_path" /usr/local/bin/sysfetch || error "Failed to create symbolic link for sysfetch"

    success "sysfetch setup completed. You can now run 'sysfetch' from anywhere in the terminal."
}

copy_wallpapers() {
    info "Setting up wallpapers..."

    ensure_dir "$CLONE_DIR"

    if [[ ! -d "$THEMES_SOURCE_DIR" ]]; then
        info "Cloning hyde-themes repository..."
        git clone --depth 1 https://github.com/hyde-themes/hyde-themes.git "$THEMES_SOURCE_DIR" ||
            error "Failed to clone hyde-themes repository"
    fi

    for theme_folder in "$THEMES_SOURCE_DIR/themes"/*(/); do
        local theme_name=${theme_folder:t}
        local dest_wallpaper_dir="$THEMES_DEST_DIR/$theme_name/wallpapers"

        if [[ -d "$dest_wallpaper_dir" ]]; then
            info "Processing theme: $theme_name"
            find "$theme_folder" -type f -print0 | while IFS= read -r -d '' file; do
                if file "$file" | grep -qi "image"; then
                    cp -f "$file" "$dest_wallpaper_dir/" && success "Copied: ${file:t}"
                fi
            done
        else
            warning "Destination folder for theme '$theme_name' does not exist. Skipping..."
        fi
    done

    success "Wallpaper copy process completed"
}

# Main execution
main() {
    info "Welcome to the HyDE Setup Script!"
    info "Created by Sayeed Mahmood Evrenos"
    echo

    ensure_dir "$CLONE_DIR"
    ensure_dir "$CONFIG_DIR"

    copy_config_files
    setup_zsh_config
    setup_grub_theme
    setup_sysfetch
    copy_wallpapers

    success "All setup tasks completed successfully!"
}

# Run main function
main "$@"