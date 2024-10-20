#!/bin/bash

# Check if running on a Debian-based system
if [ -f /etc/debian_version ]; then
    echo "Debian-based system detected. Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y libasound2-dev portaudio19-dev
elif [ -f /etc/fedora-release ]; then
    echo "Fedora-based system detected. Installing dependencies..."
    sudo dnf install -y alsa-lib-devel portaudio-devel
elif [ -f /etc/arch-release ]; then
    echo "Arch-based system detected. Installing dependencies..."
    sudo pacman -S --noconfirm alsa-lib portaudio
elif [ "$(uname)" == "Darwin" ]; then
    echo "macOS detected. Installing dependencies..."
    brew install portaudio
else
    echo "Unsupported operating system. Please install PortAudio manually."
    exit 1
fi

echo "Dependencies installed successfully."
