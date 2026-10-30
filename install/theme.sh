#!/usr/bin/env bash

# Sets the desktop-wide dark preference. Browsers (Firefox 152+, Chromium)
# read prefers-color-scheme from xdg-desktop-portal, which reads the GNOME
# color-scheme key, not the GTK theme name in gtk-3.0/settings.ini.

GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
NORMAL="$(tput sgr0)"

echo -e "\n${GREEN}Setting dark color scheme${NORMAL}"
echo "==============================${NORMAL}"

if ! command -v gsettings >/dev/null 2>&1; then
    echo -e "${YELLOW}gsettings not found, skipping${NORMAL}"
    return 0 2>/dev/null || exit 0
fi

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Matcha-dark-azul'
echo "color-scheme set to prefer-dark"
