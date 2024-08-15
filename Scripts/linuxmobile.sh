#!/bin/bash

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run as root. Exiting."
  exit 1
fi

# Function to handle errors
handle_error() {
    echo "Error on line $1"
    exit 1
}

# Trap errors
trap 'handle_error $LINENO' ERR

# Function to clone and install paru
install_paru() {
    echo "Cloning and installing paru..."
    if git clone https://aur.archlinux.org/paru.git; then
        cd paru
        makepkg -si --noconfirm
        cd ..
        rm -rf paru
    else
        echo "Failed to clone paru. Exiting."
        exit 1
    fi
}

# Install necessary packages using paru
install_packages() {
    echo "Installing packages..."
    paru -Syu --noconfirm colord ffmpegthumbnailer gnome-keyring grimblast-git gtk-engine-murrine imagemagick kvantum pamixer \
    playerctl polkit-kde-agent qt5-quickcontrols qt5-quickcontrols2 qt5-wayland qt6-wayland swww ttf-font-awesome tumbler \
    ttf-jetbrains-mono ttf-icomoon-feather xdg-desktop-portal-hyprland-git xdotool xwaylandvideobridge-cursor-mode-2-git \
    cliphist qt5-imageformats qt5ct btop cava neofetch noise-suppression-for-voice rofi-lbonn-wayland-git rofi-emoji starship \
    zsh viewnior ocs-url file-roller noto-fonts noto-fonts-cjk noto-fonts-emoji thunar thunar-archive-plugin \
    catppuccin-gtk-theme-macchiato catppuccin-gtk-theme-mocha papirus-icon-theme sddm-git swaylock-effects-git kvantum \
    kvantum-theme-catppuccin-git obs-studio-rc ffmpeg-obs cef-minimal-obs-rc-bin pipewire pipewire-alsa pipewire-audio \
    pipewire-pulse pipewire-jack wireplumber gst-plugin-pipewire pavucontrol hyprland-git hyprpicker-git waybar-git \
    dunst nwg-look wf-recorder wlogout wlsunset
}

# Function to clone Hyprland dots and synchronize files
sync_hyprland_dots() {
    echo "Cloning Hyprland dots and syncing files..."
    if git clone https://github.com/linuxmobile/hyprland-dots "$HOME/hyprland-dots/"; then
        cd "$HOME/hyprland-dots/"
        rsync -avxHAXP --exclude '.git*' .* ~/
    else
        echo "Failed to clone Hyprland dots. Exiting."
        exit 1
    fi
}

# Main execution
install_paru
install_packages
sync_hyprland_dots

echo "Script executed successfully!"
