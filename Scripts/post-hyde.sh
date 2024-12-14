#!/bin/zsh

# Exit on error
set -e

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Utility functions
print_color() {
    printf "${1}${2}${NC}\n"
}

info() { print_color "$BLUE" "[INFO] $1"; }
success() { print_color "$GREEN" "[SUCCESS] $1"; }
warning() { print_color "$YELLOW" "[WARNING] $1"; }
error() {
    print_color "$RED" "[ERROR] $1"
    exit 1
}
confirm() {
    read -q "REPLY?${1} (y/N): "
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]]
}
ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1" || error "Failed to create directory: $1"
}

# Paths
HYDE_CONFIG_DIR="$HOME/HyDE/Configs"
HYDE_SCRIPTS_DIR="$HOME/HyDE/Scripts"
CLONE_DIR="$HOME/Clone"

# Core functions
setup_zsh_config() {
    info "Setting up Zsh configuration..."

    local zshrc_source="$HYDE_CONFIG_DIR/.zshrc"
    if [[ ! -f "$zshrc_source" ]]; then
        warning ".zshrc not found in $HYDE_CONFIG_DIR. Skipping Zsh configuration setup."
        return 0
    fi

    cp -f "$zshrc_source" "$HOME/.zshrc" || error "Failed to copy .zshrc"

    # Attempt to source the new .zshrc, but don't treat as a critical error
    if source "$HOME/.zshrc"; then
        success "Zsh configuration updated and sourced."
    else
        warning "Failed to source .zshrc. Please reload manually."
    fi
}

setup_grub_theme() {
    confirm "Would you like to set up the GRUB theme?" || return 0

    local grub_themes_dir="$CLONE_DIR/grub2-themes"

    ensure_dir "$CLONE_DIR"

    if [[ ! -d "$grub_themes_dir" ]]; then
        warning "GRUB themes directory does not exist. Skipping theme setup."
        return 0
    fi

    cd "$grub_themes_dir" || error "Failed to access GRUB themes directory."

    if confirm "Would you like to edit the GRUB configuration file?"; then
        if ! sudo nano /etc/default/grub; then
            warning "Failed to open GRUB configuration for editing."
        fi
    fi

    if sudo ./install.sh -t whitesur -i whitesur; then
        success "GRUB theme installed successfully."
    else
        error "Failed to install GRUB theme."
    fi
}

setup_sysfetch() {
    info "Setting up sysfetch..."

    local sysfetch_path="$HYDE_SCRIPTS_DIR/sysfetch"

    if [[ ! -f "$sysfetch_path" ]]; then
        warning "sysfetch script not found in $HYDE_SCRIPTS_DIR. Skipping sysfetch setup."
        return 0
    fi

    chmod +x "$sysfetch_path" || error "Failed to make sysfetch executable."

    if sudo ln -sf "$sysfetch_path" /usr/local/bin/sysfetch; then
        success "sysfetch setup completed. You can now run 'sysfetch' from anywhere in the terminal."
    else
        error "Failed to create symbolic link for sysfetch."
    fi
}

# Main execution
main() {
    info "HyDE Post Setup!"
    info "Created by Evrenos"
    echo

    ensure_dir "$CLONE_DIR"

    setup_zsh_config
    setup_grub_theme
    setup_sysfetch

    success "All setup tasks completed successfully!"
}

# Run main function
main "$@"
