#!/usr/bin/env bash

# YouTube Music Theme Generator
# Syncs YouTube Music theme with the current system colors using Matugen

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
YTM_DIR="$XDG_CONFIG_HOME/YouTube Music"
SHELL_CONFIG="$XDG_CONFIG_HOME/illogical-impulse/config.json"

# Get current wallpaper and mode from quickshell config
if [ -f "$SHELL_CONFIG" ]; then
    WALLPAPER=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG")
    MODE=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
    if [[ "$MODE" == *"dark"* ]]; then
        MODE_FLAG="dark"
    else
        MODE_FLAG="light"
    fi
    PALETTE_TYPE=$(jq -r '.appearance.palette.type' "$SHELL_CONFIG" 2>/dev/null || echo "scheme-tonal-spot")
    [ "$PALETTE_TYPE" == "auto" ] && PALETTE_TYPE="scheme-tonal-spot"
else
    # Fallbacks
    WALLPAPER="$1"
    MODE_FLAG="dark"
    PALETTE_TYPE="scheme-tonal-spot"
fi

if [ -z "$WALLPAPER" ] && [ -z "$1" ]; then
    echo -e "\e[31mError: No wallpaper found in config and no image provided as argument.\e[0m"
    echo "Usage: $0 [path_to_image]"
    exit 1
fi

[ -n "$1" ] && WALLPAPER="$1"

echo -e "\e[34mGenerating YouTube Music theme using Matugen...\e[0m"
echo "Wallpaper: $WALLPAPER"
echo "Mode: $MODE_FLAG"
echo "Type: $PALETTE_TYPE"

matugen image "$WALLPAPER" --mode "$MODE_FLAG" --type "$PALETTE_TYPE"

echo -e "\n\e[32mDone! style.css has been updated in $YTM_DIR\e[0m"
echo -e "\e[33m[IMPORTANT] Manual application might be required:\e[0m"
echo -e "If the theme is not active, open YouTube Music Desktop settings,"
echo -e "go to 'Visual Tweaks', and manually import the following file:"
echo -e "\e[36m$YTM_DIR/style.css\e[0m"
