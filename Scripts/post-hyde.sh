#!/bin/zsh

# Exit on error, undefined variable, and pipe failure
set -euo pipefail

# Color definitions
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BLUE="\033[0;34m"
readonly CYAN="\033[0;36m"
readonly BOLD="\033[1m"
readonly NC="\033[0m"

# Paths
readonly HYDE_CONFIG_DIR="$HOME/HyDE/Configs"
readonly HYDE_SCRIPTS_DIR="$HOME/HyDE/Scripts"
readonly CLONE_DIR="$HOME/Clone"
readonly CONFIG_DIR="$HOME/.config"
readonly THEMES_SOURCE_DIR="$CLONE_DIR/hyde-themes"
readonly THEMES_DEST_DIR="$CONFIG_DIR/hyde/themes"

# Task flags (will be set based on user input)
DO_CONFIG=false
DO_ZSH=false
DO_GRUB=false
DO_SYSFETCH=false
DO_WALLPAPERS=false
DO_INSTALL=false

# Utility functions
print_styled() {
    printf "${1}${2}${NC}\n"
}

show_banner() {
    clear
    echo
    print_styled "$CYAN" "╭───────────────────────────────────────────╮"
    print_styled "$CYAN" "│       ${BOLD}HyDE Post-Installation Setup${NC}${CYAN}        │"
    print_styled "$CYAN" "│  Streamlined system configuration utility  │"
    print_styled "$CYAN" "╰───────────────────────────────────────────╯"
    echo
    print_styled "$BLUE" "This script will help you set up your system with:"
    echo "  1. Configuration files deployment"
    echo "  2. Zsh shell configuration"
    echo "  3. GRUB theme installation"
    echo "  4. System fetch utility setup"
    echo "  5. Theme wallpapers installation"
    echo "  6. HyDE system installation"
    echo
}

progress_bar() {
    local current=$1
    local total=$2
    local prefix=$3
    local width=30
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r${BLUE}${prefix} [${GREEN}%${completed}s${BLUE}%${remaining}s] ${percentage}%%${NC}" | tr ' ' '█' | tr '#' '░'
}

log() { print_styled "$BLUE" "┌─╼ $1"; }
success() { print_styled "$GREEN" "└─╼ Success: $1"; }
error() { print_styled "$RED" "└─╼ Error: $1"; exit 1; }

get_user_choice() {
    local prompt=$1
    while true; do
        echo -n "${CYAN}$prompt (yes/no): ${NC}"
        read -r answer
        case "${answer:l}" in
            yes|y) return 0 ;;
            no|n) return 1 ;;
            *) echo "Please answer 'yes' or 'no'";;
        esac
    done
}

ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1" || error "Failed to create directory: $1"
}

# Core functions
copy_config_files() {
    [[ "$DO_CONFIG" == "false" ]] && return 0

    log "Copying configuration files..."
    [[ -d "$HYDE_CONFIG_DIR/.config" ]] || error "Source config directory not found"

    rsync -a --info=progress2 "$HYDE_CONFIG_DIR/.config/" "$CONFIG_DIR/" ||
        error "Failed to copy configuration files"

    success "Configuration files copied"
}

setup_zsh_config() {
    [[ "$DO_ZSH" == "false" ]] && return 0

    log "Setting up Zsh configuration..."
    local zshrc_source="$HYDE_CONFIG_DIR/.zshrc"
    [[ -f "$zshrc_source" ]] || error ".zshrc not found"

    cp -f "$zshrc_source" "$HOME/.zshrc" || error "Failed to copy .zshrc"
    source "$HOME/.zshrc" 2>/dev/null || true

    success "Zsh configuration updated"
}

setup_grub_theme() {
    [[ "$DO_GRUB" == "false" ]] && return 0

    log "Setting up GRUB theme..."
    local grub_themes_dir="$CLONE_DIR/grub2-themes"

    if [[ ! -d "$grub_themes_dir" ]]; then
        git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git "$grub_themes_dir" ||
            error "Failed to clone GRUB themes repository"
    fi

    cd "$grub_themes_dir" || error "Failed to access GRUB themes directory"
    sudo ./install.sh -t whitesur -i whitesur || error "Failed to install GRUB theme"

    success "GRUB theme installed"
}

setup_sysfetch() {
    [[ "$DO_SYSFETCH" == "false" ]] && return 0

    log "Setting up sysfetch..."
    local sysfetch_path="$HYDE_SCRIPTS_DIR/sysfetch"
    [[ -f "$sysfetch_path" ]] || error "sysfetch script not found"

    chmod +x "$sysfetch_path" || error "Failed to make sysfetch executable"
    sudo ln -sf "$sysfetch_path" /usr/local/bin/sysfetch || error "Failed to create sysfetch symlink"

    success "sysfetch setup completed"
}

copy_wallpapers() {
    [[ "$DO_WALLPAPERS" == "false" ]] && return 0

    log "Setting up wallpapers..."
    ensure_dir "$CLONE_DIR"

    if [[ ! -d "$THEMES_SOURCE_DIR" ]]; then
        git clone --depth 1 https://github.com/hyde-themes/hyde-themes.git "$THEMES_SOURCE_DIR" ||
            error "Failed to clone hyde-themes repository"
    fi

    local total_themes=$(find "$THEMES_SOURCE_DIR/themes" -maxdepth 1 -type d | wc -l)
    local current=0

    find "$THEMES_SOURCE_DIR/themes" -type d -maxdepth 1 | while read theme_folder; do
        ((current++))
        local theme_name=${theme_folder:t}
        local dest_wallpaper_dir="$THEMES_DEST_DIR/$theme_name/wallpapers"

        ensure_dir "$dest_wallpaper_dir"
        rsync -a "$theme_folder/" "$dest_wallpaper_dir/" 2>/dev/null
        progress_bar "$current" "$total_themes" "Processing themes"
    done
    echo

    success "Wallpapers copied"
}

run_hyde_install() {
    [[ "$DO_INSTALL" == "false" ]] && return 0

    log "Running HyDE installation..."
    local install_script="$HYDE_SCRIPTS_DIR/install.sh"
    [[ -f "$install_script" ]] || error "Installation script not found"

    chmod +x "$install_script" || error "Failed to make install script executable"
    "$install_script" || error "HyDE installation failed"

    success "HyDE installation completed"
}

# Main execution
main() {
    show_banner

    # Choose execution mode
    echo -n "${CYAN}Select execution mode:${NC}
1) ${GREEN}Silent${NC} (run all steps)
2) ${GREEN}Interactive${NC} (choose steps to run)
Choice [1/2]: "
    read -r choice
    echo

    case $choice in
        1)
            DO_CONFIG=true
            DO_ZSH=true
            DO_GRUB=true
            DO_SYSFETCH=true
            DO_WALLPAPERS=true
            DO_INSTALL=true
            ;;
        2)
            get_user_choice "Copy configuration files?" && DO_CONFIG=true
            get_user_choice "Set up Zsh configuration?" && DO_ZSH=true
            get_user_choice "Install GRUB theme?" && DO_GRUB=true
            get_user_choice "Set up sysfetch?" && DO_SYSFETCH=true
            get_user_choice "Install wallpapers?" && DO_WALLPAPERS=true
            get_user_choice "Run HyDE installation?" && DO_INSTALL=true
            ;;
        *)
            error "Invalid choice"
            ;;
    esac

    echo
    log "Starting installation process..."
    ensure_dir "$CLONE_DIR"
    ensure_dir "$CONFIG_DIR"

    # Execute main functions
    copy_config_files
    setup_zsh_config
    setup_grub_theme
    setup_sysfetch
    copy_wallpapers
    run_hyde_install

    echo
    success "All selected tasks completed successfully!"
    echo
}

# Run main function
main "$@"