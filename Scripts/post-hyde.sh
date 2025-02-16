#!/bin/zsh

set -e  # Exit on error

# Minimal logging
log() { printf "\033[0;34m[•] %s\033[0m\n" "$1"; }
success() { printf "\033[0;32m[✔] %s\033[0m\n" "$1"; }
fail() { printf "\033[0;31m[✘] %s\033[0m\n" "$1"; exit 1; }
confirm() { read -q "?${1} (y/N): "; echo; [[ "$REPLY" =~ ^[Yy]$ ]]; }

# Ensure required commands exist
check_cmd() { command -v "$1" >/dev/null 2>&1 || fail "$1 not installed. Install it manually."; }

# Paths
CLONE_DIR="$HOME/Clone"
mkdir -p "$CLONE_DIR"

# Rustor Setup
setup_rustor() {
    log "Installing Rustor..."
    check_cmd git; check_cmd cargo
    cd "$CLONE_DIR" && rm -rf rustor
    git clone https://github.com/Evren-os/rustor.git || fail "Rustor clone failed"
    cd rustor && cargo build --release || fail "Rustor build failed"
    sudo mv ./target/release/rustor /usr/local/bin/ || fail "Rustor install failed"
    success "Rustor installed"
}

# GRUB Theme Setup
setup_grub_theme() {
    confirm "Setup GRUB theme?" || return
    log "Installing GRUB theme..."
    check_cmd git
    cd "$CLONE_DIR" && rm -rf grub2-themes
    git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git || fail "GRUB clone failed"
    cd grub2-themes && sudo ./install.sh -t whitesur -i whitesur || fail "GRUB theme install failed"
    success "GRUB theme installed"
}

# Sysfetch Setup
setup_sysfetch() {
    log "Setting up sysfetch..."
    local sysfetch_path="$HOME/HyDE/Scripts/sysfetch"
    [[ -f "$sysfetch_path" ]] || { log "sysfetch not found, skipping"; return; }
    chmod +x "$sysfetch_path" || fail "sysfetch chmod failed"
    sudo cp "$sysfetch_path" /usr/local/bin/sysfetch || fail "sysfetch install failed"
    success "sysfetch installed"
}

# SDDM Astronaut Theme Setup
setup_sddm_theme() {
    confirm "Setup SDDM Astronaut theme?" || return
    log "Installing SDDM Astronaut theme..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)" || fail "SDDM Astronaut theme install failed"
    success "SDDM Astronaut theme installed"
}

# Main Execution
main() {
    log "HyDE Post Setup"
    [[ ! -f /etc/arch-release ]] && fail "Not an Arch-based system"
    [[ "$EUID" -eq 0 ]] && fail "Do not run as root"
    setup_rustor
    setup_grub_theme
    setup_sysfetch
    setup_sddm_theme
    success "Setup complete"
}

main "$@"
