#!/bin/bash
# LC3 C Compiler - Raspberry Pi Setup Script (Part 1)
# Run this first, then reboot, then run install-lc3.sh

set -e

echo "=== LC3 C Compiler - Raspberry Pi Setup ==="
echo ""

# Update and upgrade system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "Installing dependencies (git, cmake)..."
sudo apt-get install git cmake -y

# Setup local bin directory
echo "Setting up ~/.local/bin directory..."
mkdir -p ~/.local/bin

# Add to PATH if not already present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "Added ~/.local/bin to PATH in .bashrc"
else
    echo "PATH already configured in .bashrc"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "If the system needs to reboot (kernel update), reboot now:"
echo "  sudo reboot"
echo ""
echo "After reboot, run the install script:"
echo "  cd C-LC3-Compiler && ./scripts/install-lc3.sh"
echo ""
echo "Or if you haven't cloned the repo yet:"
echo "  git clone https://github.com/lkoepsel/C-LC3-Compiler.git"
echo "  cd C-LC3-Compiler && ./scripts/install-lc3.sh"
