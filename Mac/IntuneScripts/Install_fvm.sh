#!/bin/zsh

####################################################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# This script installs FVM (Flutter Version Management) on macOS systems
# without requiring sudo/admin access.
#
# Features:
# 1. Supports both Intel and Apple Silicon (M1/M2/M3) Macs
# 2. Installs FVM inside:
#       $HOME/cli/fvm
# 3. Automatically detects shell type
# 4. Automatically updates ~/.zshrc
# 5. Adds Dart pub cache binary path
# 6. Verifies installation after setup
# 7. Works fully in user-space without sudo
#
# Requirements:
# - Internet connection
# - curl installed
#
####################################################################################################

# Exit immediately if a command exits with non-zero status
set -e

########################################
# VARIABLES
########################################

INSTALL_DIR="$HOME/cli/fvm"
DART_SDK_DIR="$HOME/.pub-cache/bin"
ZSHRC_FILE="$HOME/.zshrc"

########################################
# CREATE INSTALL DIRECTORY
########################################

echo "=================================================="
echo "Creating installation directory..."
echo "=================================================="

mkdir -p "$INSTALL_DIR"

########################################
# DETECT MAC ARCHITECTURE
########################################

echo "=================================================="
echo "Detecting Mac architecture..."
echo "=================================================="

ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    echo "Apple Silicon Mac detected (M1/M2/M3)"
elif [[ "$ARCH" == "x86_64" ]]; then
    echo "Intel Mac detected"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

########################################
# CHECK IF DART EXISTS
########################################

echo "=================================================="
echo "Checking if Dart SDK exists..."
echo "=================================================="

if command -v dart >/dev/null 2>&1; then
    echo "Dart is already installed."
else
    echo "Dart SDK not found."
    echo ""
    echo "FVM requires Dart SDK."
    echo ""
    echo "Install Flutter manually first OR"
    echo "install Dart SDK in user-space."
    echo ""
    echo "Official Dart SDK:"
    echo "https://dart.dev/get-dart"
    exit 1
fi

########################################
# INSTALL FVM USING DART PUB
########################################

echo "=================================================="
echo "Installing FVM..."
echo "=================================================="

PUB_CACHE="$INSTALL_DIR/pub-cache"

mkdir -p "$PUB_CACHE"

export PUB_CACHE="$PUB_CACHE"

dart pub global activate fvm

########################################
# VERIFY INSTALLATION
########################################

FVM_BINARY="$PUB_CACHE/bin/fvm"

if [[ ! -f "$FVM_BINARY" ]]; then
    echo "FVM installation failed."
    exit 1
fi

echo "FVM installed successfully."

########################################
# UPDATE ZSHRC
########################################

echo "=================================================="
echo "Updating ~/.zshrc..."
echo "=================================================="

FVM_PATH_EXPORT="export PATH=\"$PUB_CACHE/bin:\$PATH\""

# Prevent duplicate entries
if grep -Fxq "$FVM_PATH_EXPORT" "$ZSHRC_FILE"; then
    echo "PATH entry already exists in .zshrc"
else
    echo "" >> "$ZSHRC_FILE"
    echo "# FVM PATH" >> "$ZSHRC_FILE"
    echo "$FVM_PATH_EXPORT" >> "$ZSHRC_FILE"
    echo "Added FVM path to .zshrc"
fi

########################################
# RELOAD ZSHRC
########################################

echo "=================================================="
echo "Reloading shell configuration..."
echo "=================================================="

export PATH="$PUB_CACHE/bin:$PATH"

source "$ZSHRC_FILE"

########################################
# FINAL VALIDATION
########################################

echo "=================================================="
echo "Validating FVM installation..."
echo "=================================================="

if command -v fvm >/dev/null 2>&1; then
    echo ""
    echo "FVM installed successfully!"
    echo ""
    fvm --version
else
    echo "FVM command not found after installation."
    exit 1
fi

########################################
# INSTALL LOCATION INFO
########################################

echo ""
echo "=================================================="
echo "INSTALLATION DETAILS"
echo "=================================================="
echo "FVM Install Location : $INSTALL_DIR"
echo "Pub Cache Location   : $PUB_CACHE"
echo "Shell Config File    : $ZSHRC_FILE"
echo "=================================================="
echo ""

echo "You may now use:"
echo "fvm install stable"
echo "fvm use stable"
echo ""
