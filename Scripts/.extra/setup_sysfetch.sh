#!/bin/bash

# Simplified setup script for sysfetch

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

# Check if the sysfetch script exists
if [ ! -f ~/HyDE/Scripts/sysfetch ]; then
    print_color "${RED}" "Error: sysfetch script not found in ~/HyDE/Scripts/"
    exit 1
fi

# Make sysfetch executable
chmod +x ~/HyDE/Scripts/sysfetch
print_color "${GREEN}" "Made sysfetch executable"

# Create a symbolic link in /usr/local/bin
sudo ln -sf ~/HyDE/Scripts/sysfetch /usr/local/bin/sysfetch
print_color "${GREEN}" "Created symbolic link to sysfetch in /usr/local/bin"

print_color "${GREEN}" "Setup complete! You can now run 'sysfetch' from anywhere in the terminal."