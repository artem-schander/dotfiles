#!/bin/bash

echo -e "\n\n${GREEN}Setting up zram and memory protection${NORMAL}"
echo "=============================="

# Only run on Linux
if [[ "$(uname)" == "Darwin" ]]; then
    echo "macOS detected, skipping zram setup (not needed)"
    return 0 2>/dev/null || exit 0
fi

# Detect OS if not already set (allows running standalone)
if [[ -z "$OS" ]]; then
    QUIET=true source "$(dirname "${BASH_SOURCE[0]}")/recognize-os.sh"
fi

# Install zram-generator
if [[ "$OS" == "Arch" ]]; then
    if ! pacman -Q zram-generator >/dev/null 2>&1; then
        echo "Installing zram-generator..."
        sudo pacman -S zram-generator --noconfirm
    else
        echo "zram-generator already installed, skipping..."
    fi

    if ! pacman -Q earlyoom >/dev/null 2>&1; then
        echo "Installing earlyoom..."
        sudo pacman -S earlyoom --noconfirm
    else
        echo "earlyoom already installed, skipping..."
    fi
elif [[ "$OS" == "Ubuntu" ]]; then
    if ! dpkg -l systemd-zram-generator >/dev/null 2>&1; then
        echo "Installing systemd-zram-generator..."
        sudo apt-get install -y systemd-zram-generator
    else
        echo "systemd-zram-generator already installed, skipping..."
    fi

    if ! dpkg -l earlyoom >/dev/null 2>&1; then
        echo "Installing earlyoom..."
        sudo apt-get install -y earlyoom
    else
        echo "earlyoom already installed, skipping..."
    fi
fi

# Create zram config
echo "Configuring zram..."
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# Create sysctl tuning for zram
echo "Configuring sysctl for zram..."
sudo tee /etc/sysctl.d/99-zram.conf > /dev/null << 'EOF'
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# Apply sysctl settings
sudo sysctl --system > /dev/null 2>&1

# Enable earlyoom (kills processes gracefully before system freezes)
echo "Enabling earlyoom..."
sudo systemctl enable --now earlyoom 2>/dev/null || true

# Start zram
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0 2>/dev/null || true

# Verify
echo ""
echo "zram devices:"
zramctl 2>/dev/null || echo "  (will be active after reboot)"
echo ""
echo "Swap devices:"
swapon --show 2>/dev/null

echo -e "\n${GREEN}zram and memory protection setup completed!${NORMAL}"
echo -e "${YELLOW}Note: A reboot is recommended for optimal memory management.${NORMAL}"
