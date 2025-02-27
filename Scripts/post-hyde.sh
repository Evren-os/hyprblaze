#!/bin/zsh

log() { printf "[*] %s\n" "$1"; }
success() { printf "[✔] %s\n" "$1"; }
fail() { printf "[✘] %s\n" "$1"; return 1; }
confirm() { read -q "?${1} (y/N): "; echo; [[ "$REPLY" =~ ^[Yy]$ ]]; }

check_cmd() { command -v "$1" >/dev/null 2>&1 || { fail "$1 not installed. Install it manually."; return 1; } }

CLONE_DIR="$HOME/Clone"
mkdir -p "$CLONE_DIR"

setup_rustor() {
    log "Installing Rustor..."
    check_cmd git || return 1
    check_cmd cargo || return 1
    cd "$CLONE_DIR" || return 1
    if [ -d "rustor" ]; then
        log "Using existing rustor repository."
    else
        git clone https://github.com/Evren-os/rustor.git || return 1
    fi
    cd rustor || return 1
    cargo build --release || return 1
    sudo mv ./target/release/rustor /usr/local/bin/ || return 1
    success "Rustor installed"
}

setup_grub_theme() {
    log "Installing GRUB theme..."
    check_cmd git || return 1
    cd "$CLONE_DIR" || return 1
    if [ -d "grub2-themes" ]; then
        log "Using existing grub2-themes repository."
    else
        git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git || return 1
    fi
    cd grub2-themes || return 1
    sudo ./install.sh -t whitesur -i whitesur || return 1
    success "GRUB theme installed"
}

setup_sysfetch() {
    log "Setting up sysfetch..."
    local sysfetch_path="$HOME/HyDE/Scripts/sysfetch"
    if [ ! -f "$sysfetch_path" ]; then
        log "sysfetch not found, skipping"
        return 0
    fi
    chmod +x "$sysfetch_path" || return 1
    sudo cp "$sysfetch_path" /usr/local/bin/sysfetch || return 1
    success "sysfetch installed"
}

setup_sddm_theme_silent() {
    log "Setting up SDDM theme..."
    if command -v pacman >/dev/null 2>&1; then
         sudo pacman --noconfirm --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg >/dev/null 2>&1
    elif command -v xbps-install >/dev/null 2>&1; then
         sudo xbps-install sddm qt6-svg qt6-virtualkeyboard qt6-multimedia >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
         sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia >/dev/null 2>&1
    elif command -v zypper >/dev/null 2>&1; then
         sudo zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia qt6-multimedia-imports >/dev/null 2>&1
    fi

    local theme_dir="$HOME/sddm-astronaut-theme"
    if [ -d "$theme_dir" ]; then
         sudo mv "$theme_dir" "${theme_dir}_backup_$(date +%s)" >/dev/null 2>&1
    fi
    git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git "$theme_dir" >/dev/null 2>&1

    local target_dir="/usr/share/sddm/themes/sddm-astronaut-theme"
    if [ -d "$target_dir" ]; then
         sudo mv "$target_dir" "${target_dir}_backup_$(date +%s)" >/dev/null 2>&1
    fi
    sudo mkdir -p "$target_dir" >/dev/null 2>&1
    sudo cp -r "$theme_dir/"* "$target_dir" >/dev/null 2>&1
    sudo cp -r "$target_dir/Fonts/"* /usr/share/fonts/ >/dev/null 2>&1

    echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf >/dev/null 2>&1
    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null 2>&1
    local metadata="/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
    sudo sed -i 's|^ConfigFile=Themes/.*|ConfigFile=Themes/pixel_sakura.conf|' "$metadata" >/dev/null 2>&1

    log "SDDM theme setup complete."
}

main() {
    log "HyDE Post Setup"
    if [ ! -f /etc/arch-release ]; then
        fail "Not an Arch-based system"
        exit 1
    fi
    if [ "$EUID" -eq 0 ]; then
        fail "Do not run as root"
        exit 1
    fi

    setup_rustor || log "Rustor setup failed, continuing..."
    setup_grub_theme || log "GRUB theme setup failed, continuing..."
    setup_sysfetch || log "sysfetch setup failed, continuing..."
    setup_sddm_theme_silent || log "SDDM theme setup failed, continuing..."

    success "Setup complete"
}

main "$@"
