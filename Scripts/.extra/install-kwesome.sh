#!/usr/bin/env bash

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logger function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should NOT be run as root"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create directory if it doesn't exist
create_dir_if_not_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || error "Failed to create directory: $dir"
    fi
}

# System upgrade
system_upgrade() {
    log "Performing full system upgrade..."
    sudo pacman -Syu --noconfirm || error "System upgrade failed"
}

# Install paru
install_paru() {
    log "Installing paru-bin..."
    local clone_dir="$HOME/Clone"
    create_dir_if_not_exists "$clone_dir"
    cd "$clone_dir" || error "Failed to change directory to $clone_dir"

    if ! command_exists paru; then
        git clone https://aur.archlinux.org/paru-bin.git || error "Failed to clone paru-bin"
        cd paru-bin || error "Failed to change directory to paru-bin"
        makepkg -si --noconfirm || error "Failed to install paru-bin"
    else
        warning "paru is already installed"
    fi
}

# Install AwesomeWM
install_awesome() {
    log "Installing AwesomeWM..."
    paru -S awesome-git --noconfirm || error "Failed to install awesome-git"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."

    # System packages
    sudo pacman -Sy --needed --noconfirm \
        networkmanager nm-connection-editor bluez blueman \
        pipewire pipewire-pulse libgusb libgudev upower \
        lm_sensors brightnessctl redshift inotify-tools \
        maim xcolor ffmpeg playerctl fortune-mod \
        imagemagick neofetch libsecret || error "Failed to install system dependencies"

    # AUR packages
    paru -S --needed --noconfirm picom-animations-git || error "Failed to install picom-animations-git"
}

# Install fonts
install_fonts() {
    log "Installing fonts..."

    # Install nerd fonts
    local fonts=(
        ttf-cascadia-code-nerd
        ttf-iosevka-nerd
        ttf-jetbrains-mono-nerd
        ttf-zed-mono-nerd
        ttf-meslo-nerd
        ttf-nerd-fonts-symbols
        ttf-nerd-fonts-symbols-mono
        ttf-cascadia-mono-nerd
    )

    sudo pacman -Sy --needed --noconfirm "${fonts[@]}" || error "Failed to install nerd fonts"

    # Install Oswald font
    local clone_dir="$HOME/Clone"
    local fonts_dir="$HOME/.local/share/fonts"

    create_dir_if_not_exists "$clone_dir"
    create_dir_if_not_exists "$fonts_dir"

    cd "$clone_dir" || error "Failed to change directory to $clone_dir"
    wget https://raw.githubusercontent.com/Evren-os/hyprblaze/refs/heads/main/Source/misc/Oswald.zip || error "Failed to download Oswald font"
    unzip Oswald.zip -d Oswald || error "Failed to unzip Oswald font"
    cp -r Oswald/* "$fonts_dir/" || error "Failed to copy Oswald font"

    # Update font cache
    fc-cache -v || error "Failed to update font cache"
}

# Install KwesomeDE
install_kwesome() {
    log "Installing KwesomeDE..."
    local awesome_config_dir="$HOME/.config/awesome"

    # Backup existing config if it exists
    if [[ -d "$awesome_config_dir" ]]; then
        mv "$awesome_config_dir" "${awesome_config_dir}.backup.$(date +%Y%m%d_%H%M%S)" || error "Failed to backup existing awesome config"
    fi

    git clone --recurse-submodules https://github.com/Kasper24/KwesomeDE "$awesome_config_dir" || error "Failed to clone KwesomeDE"
}

# Install and configure COSMIC Greeter
install_display_manager() {
    log "Installing and configuring COSMIC Greeter..."

    # Install COSMIC Greeter and its dependencies
    sudo pacman -Sy --needed --noconfirm \
        cosmic-greeter xorg-server lightdm lightdm-gtk-greeter \
        accountsservice || error "Failed to install display manager packages"

    # Configure LightDM to use COSMIC Greeter
    sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup || error "Failed to backup lightdm.conf"

    # Update LightDM configuration
    sudo tee /etc/lightdm/lightdm.conf > /dev/null <<EOF || error "Failed to update lightdm.conf"
[Seat:*]
greeter-session=cosmic-greeter
user-session=awesome
EOF

    # Enable LightDM service
    sudo systemctl enable lightdm.service || error "Failed to enable lightdm service"

    # Create Awesome WM session file
    sudo tee /usr/share/xsessions/awesome.desktop > /dev/null <<EOF || error "Failed to create awesome.desktop"
[Desktop Entry]
Name=Awesome
Comment=Highly configurable framework window manager
Exec=awesome
TryExec=awesome
Type=Application
EOF

    log "Display manager configuration completed"
}

# Enable essential services
enable_services() {
    log "Enabling essential services..."

    local services=(
        "NetworkManager"
        "bluetooth"
        "pipewire"
        "pipewire-pulse"
    )

    for service in "${services[@]}"; do
        sudo systemctl enable "$service" || warning "Failed to enable $service"
        sudo systemctl start "$service" || warning "Failed to start $service"
    done
}

# Main installation function
main() {
    log "Starting installation..."

    # Check if running as root
    check_root

    # Execute installation steps
    system_upgrade
    install_paru
    install_awesome
    install_dependencies
    install_fonts
    install_kwesome
    install_display_manager
    enable_services

    log "Installation completed successfully!"
    log "The system will use COSMIC Greeter as the display manager."
    log "Please reboot your system to start using KwesomeDE with COSMIC Greeter."
    log "After reboot, select AwesomeWM from the session menu in COSMIC Greeter."
}

# Execute main function
main "$@"