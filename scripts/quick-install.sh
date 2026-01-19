#!/bin/bash
# LC3 C Compiler - Quick Install Script
# For RPi: 
# Step 1: Update and Upgrade OS (manual entry)
# sudo apt update && sudo apt full-upgrade -y
# Step 2: Clone, build and test C compiler (this shell script)
#   curl -fsSL https://raw.githubusercontent.com/lkoepsel/C-LC3-Compiler/main/scripts/quick-install.sh | bash

set -e

echo "=== LC3 C Compiler - Quick Install ==="
echo ""

# Update and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt-get install git cmake -y

# Setup local bin directory
echo "Setting up ~/.local/bin directory..."
mkdir -p ~/.local/bin

# Add to PATH if not already present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.local/bin:$PATH"

# Clone repository if not already present
if [ ! -d "$HOME/C-LC3-Compiler" ]; then
    echo "Cloning C-LC3-Compiler repository..."
    cd "$HOME"
    git clone https://github.com/lkoepsel/C-LC3-Compiler.git
fi

# Build and install
cd "$HOME/C-LC3-Compiler"
echo "Building LC3 C Compiler..."
mkdir -p build
cd build
cmake ..
make

echo "Installing lc3-compile to ~/.local/bin..."
cp lc3-compile ~/.local/bin/

# Test the installation
echo ""
echo "Testing installation..."
cd "$HOME/C-LC3-Compiler/examples/add"
lc3-compile main.c -S -v -o main.asm

echo ""
echo "=== Installation complete ==="
echo ""
echo "Restart your terminal or run: source ~/.bashrc"
echo "Then use: lc3-compile <file.c> -S -v -o <output.asm>"
