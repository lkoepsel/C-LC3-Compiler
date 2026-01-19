#!/bin/bash
# LC3 C Compiler - Build and Install Script (Part 2)
# Run this after setup-rpi.sh and reboot

set -e

echo "=== LC3 C Compiler - Build and Install ==="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Ensure local bin exists
mkdir -p ~/.local/bin

# Source bashrc to get PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Build the compiler
echo "Building LC3 C Compiler..."
mkdir -p build
cd build
cmake ..
make

# Install to local bin
echo "Installing lc3-compile to ~/.local/bin..."
cp lc3-compile ~/.local/bin/

# Test the installation
echo ""
echo "Testing installation..."
cd "$PROJECT_DIR/examples/add"
lc3-compile main.c -S -v -o main.asm

echo ""
echo "=== Installation complete ==="
echo ""
echo "The lc3-compile command is now available."
echo "Usage: lc3-compile <file.c> -S -v -o <output.asm>"
