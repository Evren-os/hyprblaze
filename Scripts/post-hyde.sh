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

# Dependency Installation
install_dependencies() {
    info "Checking and installing dependencies..."

    # Ensure system is up to date
    sudo pacman -Syu --noconfirm || error "Failed to update system packages"

    # Install Git if not present
    if ! command -v git >/dev/null 2>&1; then
        info "Installing Git..."
        sudo pacman -S --noconfirm git || error "Failed to install Git"
        success "Git installed successfully"
    else
        info "Git is already installed"
    fi

    # Install Rust and Cargo if not present
    if ! command -v rustc >/dev/null 2>&1 || ! command -v cargo >/dev/null 2>&1; then
        info "Installing Rust and Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || error "Failed to install Rust"

        # Source cargo environment
        source "$HOME/.cargo/env"

        success "Rust and Cargo installed successfully"
    else
        info "Rust and Cargo are already installed"
    fi

    # Additional system dependencies
    local deps=("base-devel" "wget" "curl")
    for dep in "${deps[@]}"; do
        if ! pacman -Q "$dep" >/dev/null 2>&1; then
            info "Installing $dep..."
            sudo pacman -S --noconfirm "$dep" || error "Failed to install $dep"
        fi
    done

    success "All dependencies are installed and up to date"
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

setup_rustor() {
    info "Building and installing Rustor..."

    ensure_dir "$CLONE_DIR"
    cd "$CLONE_DIR"

    # Remove existing rustor directory if it exists
    [[ -d "rustor" ]] && rm -rf rustor

    # Ensure Rust environment is sourced
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    # Clone and build Rustor
    git clone https://github.com/Evren-os/rustor.git || error "Failed to clone Rustor repository"
    cd rustor

    # Build Rustor
    cargo build --release || error "Failed to build Rustor"

    # Move binary to system path
    sudo mv ./target/release/rustor /usr/local/bin/ || error "Failed to install Rustor"

    success "Rustor installed successfully to /usr/local/bin/rustor"
}

setup_grub_theme() {
    confirm "Would you like to set up the GRUB theme?" || return 0

    info "Setting up GRUB theme..."
    ensure_dir "$CLONE_DIR"
    cd "$CLONE_DIR"

    # Remove existing grub2-themes directory if it exists
    [[ -d "grub2-themes" ]] && rm -rf grub2-themes

    # Clone GRUB themes repository
    git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git || error "Failed to clone GRUB themes repository"
    cd grub2-themes

    # Optional: Edit GRUB configuration
    if confirm "Would you like to edit the GRUB configuration file?"; then
        if ! sudo nano /etc/default/grub; then
            warning "Failed to open GRUB configuration for editing."
        fi
    fi

    # Install GRUB theme
    sudo ./install.sh -t whitesur -i whitesur || error "Failed to install GRUB theme"

    success "GRUB theme installed successfully."
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

    # Verify running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux only!"
    fi

    # Check for sudo/root privileges
    if [[ "$EUID" -eq 0 ]]; then
        error "Do not run this script as root. Use sudo if needed."
    fi

    ensure_dir "$CLONE_DIR"

    # Install dependencies first
    install_dependencies

    # Run setup functions
    setup_zsh_config
    setup_rustor
    setup_grub_theme
    setup_sysfetch

    success "All setup tasks completed successfully!"

    # Prompt for system reboot
    if confirm "Would you like to reboot now?"; then
        sudo reboot
    fi
}

# Run main function
main "$@"