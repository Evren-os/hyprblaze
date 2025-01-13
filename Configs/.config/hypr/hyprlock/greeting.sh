#!/bin/bash

# Read the username alias from hyprlock.conf (optional, not used in greeting)
username=$(grep -oP '^\$USER\s*=\s*\K\S+' ~/.config/hypr/hyprlock.conf)

# Get the current hour
hour=$(date +%H)

# Determine the edgy greeting based on the time
if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
    greeting="Boot sequence initiated. Survive the bugs."
elif [ "$hour" -ge 12 ] && [ "$hour" -lt 17 ]; then
    greeting="Code or die. Afternoon's wasting."
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 21 ]; then
    greeting="Deploying vibes. Debug the evening."
elif [ "$hour" -ge 21 ] && [ "$hour" -lt 24 ]; then
    greeting="Late commits again? Touch grass tomorrow."
else
    greeting="Kernel panic. Sleep, you nerd."
fi


# Output the combined text
echo -e "$greeting"
