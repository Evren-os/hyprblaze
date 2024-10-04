#!/bin/bash

# Script Introduction
echo "Welcome to the Wallpaper Copy Script!"
echo "This script copies wallpapers from the 'hyde-themes' repository to your specified directory."
echo "Created by Sayeed Mahmood Evrenos"
echo

# Source and destination directories
base_dir="$HOME/Clone"
source_dir="$base_dir/hyde-themes"
dest_dir="$HOME/.config/hyde/themes"

# Check if the 'Clone' directory exists, if not, create it
if [ ! -d "$base_dir" ]; then
    echo "Directory '$base_dir' does not exist. Creating it..."
    mkdir -p "$base_dir"
    echo "Directory '$base_dir' created."
fi

# Check if 'hyde-themes' directory exists inside 'Clone', if not, clone the repo
if [ ! -d "$source_dir" ]; then
    echo "Directory '$source_dir' does not exist. Cloning repository..."
    git clone --depth 1 https://github.com/hyde-themes/hyde-themes.git "$source_dir"
    if [ $? -eq 0 ]; then
        echo "Repository successfully cloned to '$source_dir'."
    else
        echo "Error: Failed to clone repository."
        exit 1
    fi
fi

# Function to copy files with override
copy_with_override() {
    local src="$1"
    local dest="$2"
    cp -f "$src" "$dest"
    echo "Copied: $(basename "$src")"
}

# Loop through each theme folder
for theme_folder in "$source_dir/themes"/*; do
    if [ -d "$theme_folder" ]; then
        theme_name=$(basename "$theme_folder")

        # Check if the destination folder exists
        if [ -d "$dest_dir/$theme_name/wallpapers" ]; then
            echo "Processing theme: $theme_name"

            # Check if the source folder is not empty
            if [ "$(ls -A "$theme_folder")" ]; then
                # Copy wallpapers (supporting all image formats) with override
                find "$theme_folder" -type f -print0 | while IFS= read -r -d '' file; do
                    if file "$file" | grep -qi "image"; then
                        copy_with_override "$file" "$dest_dir/$theme_name/wallpapers/"
                    fi
                done
            else
                echo "Skipping empty folder: $theme_name"
            fi
        else
            echo "Destination folder for theme '$theme_name' does not exist. Skipping..."
        fi
    fi
done

echo
echo "Wallpaper copy process completed."
