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
# 3. Automatically updates ~/.zshrc
# 4. Automatically reloads shell configuration
# 5. Adds FVM binary path automatically
# 6. Performs installation validation
# 7. Works fully in user-space without sudo access
#
# Requirements:
# - Internet connection
# - Dart SDK installed
#
####################################################################################################

# Exit script immediately if any command fails
set -e

########################################
# VARIABLES
########################################

INSTALL_DIR="$HOME/cli/fvm"
PUB_CACHE_DIR="$INSTALL_DIR/pub-cache"
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
    echo "Unsupported architecture detected: $ARCH"
    exit 1
fi

########################################
# CHECK DART INSTALLATION
########################################

echo "=================================================="
echo "Checking Dart SDK..."
echo "=================================================="

if command -v dart >/dev/null 2>&1; then
    echo "Dart SDK detected."
else
    echo "ERROR: Dart SDK not found."
    echo ""
    echo "FVM requires Dart SDK to be installed first."
    echo ""
    echo "Install Dart SDK from:"
    echo "https://dart.dev/get-dart"
    exit 1
fi

########################################
# CONFIGURE PUB CACHE
########################################

echo "=================================================="
echo "Configuring Pub Cache..."
echo "=================================================="

mkdir -p "$PUB_CACHE_DIR"

export PUB_CACHE="$PUB_CACHE_DIR"

########################################
# INSTALL FVM
########################################

echo "=================================================="
echo "Installing FVM..."
echo "=================================================="

dart pub global activate fvm

########################################
# VERIFY FVM BINARY
########################################

FVM_BINARY="$PUB_CACHE_DIR/bin/fvm"

if [[ ! -f "$FVM_BINARY" ]]; then
    echo "ERROR: FVM installation failed."
    exit 1
fi

echo "FVM installation completed."

########################################
# UPDATE .ZSHRC
########################################

echo "=================================================="
echo "Updating ~/.zshrc..."
echo "=================================================="

FVM_PATH='export PATH="$HOME/cli/fvm/pub-cache/bin:$PATH"'

# Create .zshrc if it does not exist
touch "$ZSHRC_FILE"

# Prevent duplicate PATH entries
if grep -Fxq "$FVM_PATH" "$ZSHRC_FILE"; then
    echo "FVM PATH already exists in .zshrc"
else
    {
        echo ""
        echo "# FVM PATH"
        echo "$FVM_PATH"
    } >> "$ZSHRC_FILE"

    echo "FVM PATH added to .zshrc"
fi

########################################
# RELOAD ZSHRC
########################################

echo "=================================================="
echo "Reloading ~/.zshrc..."
echo "=================================================="

# Load updated shell configuration
source "$ZSHRC_FILE"

########################################
# EXPORT PATH FOR CURRENT SESSION
########################################

export PATH="$HOME/cli/fvm/pub-cache/bin:$PATH"

########################################
# VALIDATE INSTALLATION
########################################

echo "=================================================="
echo "Validating FVM installation..."
echo "=================================================="

if command -v fvm >/dev/null 2>&1; then
    echo ""
    echo "FVM installed successfully."
    echo ""
    echo "Installed Version:"
    fvm --version
else
    echo "ERROR: FVM command not found."
    exit 1
fi

########################################
# DISPLAY INSTALLATION DETAILS
########################################

echo ""
echo "=================================================="
echo "INSTALLATION DETAILS"
echo "=================================================="
echo "Install Directory : $INSTALL_DIR"
echo "Pub Cache Path    : $PUB_CACHE_DIR"
echo "Shell Config File : $ZSHRC_FILE"
echo "=================================================="
echo ""

echo "Usage Examples:"
echo "fvm install stable"
echo "fvm use stable"
echo ""
