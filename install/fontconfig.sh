#!/usr/bin/env bash

# Symlinks the dotfiles' fontconfig drop-ins into ~/.config/fontconfig/conf.d.
# fontconfig's conf.d is a SHARED directory (the system and Font Manager also
# write files here), so we link individual files rather than the whole dir.

DOTFILES=$HOME/.dotfiles

GREEN="$(tput setaf 2)"
NORMAL="$(tput sgr0)"

echo -e "\n${GREEN}Linking fontconfig drop-ins${NORMAL}"
echo "==============================${NORMAL}"

SRC_DIR="$DOTFILES/config/fontconfig/conf.d"
DEST_DIR="$HOME/.config/fontconfig/conf.d"

mkdir -p "$DEST_DIR"

for conf in "$SRC_DIR"/*.conf; do
    [ -e "$conf" ] || continue
    dest="$DEST_DIR/$(basename "$conf")"
    ln -sf "$conf" "$dest"
    echo "Linked $(basename "$conf")"
done

# Refresh the font cache so the new fallback rules take effect immediately.
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1
    echo "Font cache refreshed"
fi
