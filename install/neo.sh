#!/bin/bash

# Install neo - Matrix digital rain terminal effect
# https://github.com/st3w/neo
#
# Supports: macOS, Ubuntu, Arch Linux
# Can run standalone or sourced from dotfiles installer

set -e

NEO_REPO="https://github.com/st3w/neo.git"
NEO_BUILD_DIR="/tmp/neo-build"

# Source OS detection if not already set
if [ -z "$OS" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/recognize-os.sh" ]; then
        source "$SCRIPT_DIR/recognize-os.sh"
    else
        # Standalone detection
        if [ "$(uname)" == "Darwin" ]; then
            OS=Darwin
        elif [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian) OS=Ubuntu ;;
                arch|manjaro) OS=Arch ;;
                *) echo "Unsupported OS: $ID"; exit 1 ;;
            esac
        else
            echo "Unable to detect OS"; exit 1
        fi
    fi
fi

install_dependencies() {
    echo "Installing neo dependencies..."
    case "$OS" in
        Darwin)
            brew install autoconf automake ncurses
            ;;
        Ubuntu)
            sudo apt-get update
            sudo apt-get install -y build-essential libncurses-dev autoconf automake
            ;;
        Arch)
            sudo pacman -S --needed --noconfirm base-devel ncurses autoconf automake
            ;;
    esac
}

build_and_install() {
    echo "Cloning neo..."
    rm -rf "$NEO_BUILD_DIR"
    git clone "$NEO_REPO" "$NEO_BUILD_DIR"
    cd "$NEO_BUILD_DIR"

    echo "Building neo..."
    ./autogen.sh

    if [ "$OS" == "Darwin" ]; then
        export LDFLAGS="-L/opt/homebrew/opt/ncurses/lib"
        export CPPFLAGS="-I/opt/homebrew/opt/ncurses/include"
    fi

    ./configure
    make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
    sudo make install

    echo "Cleaning up..."
    rm -rf "$NEO_BUILD_DIR"

    echo "neo installed successfully!"
}

install_dependencies
build_and_install
