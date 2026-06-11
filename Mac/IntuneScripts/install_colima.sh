#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima for the current user.
# - Supports both Intel and Apple Silicon Macs.
# - Installs Colima into ~/.local/bin.
# - Adds ~/.local/bin to PATH if necessary.
# - Updates ~/.zshrc.
# - Sources ~/.zshrc automatically.
# - Verifies the installation.
###############################################################################

###############################################################################
# Exit immediately if a command fails.
###############################################################################
set -e

###############################################################################
# Define installation directories.
###############################################################################
INSTALL_DIR="$HOME/.local/bin"
COLIMA_BIN="$INSTALL_DIR/colima"

###############################################################################
# Create the installation directory if it does not exist.
###############################################################################
mkdir -p "$INSTALL_DIR"

###############################################################################
# Determine the system architecture.
###############################################################################
ARCH=$(uname -m)

case "$ARCH" in
    arm64)
        DOWNLOAD_URL="https://github.com/abiosoft/colima/releases/latest/download/colima-Darwin-arm64"
        ;;
    x86_64)
        DOWNLOAD_URL="https://github.com/abiosoft/colima/releases/latest/download/colima-Darwin-x86_64"
        ;;
    *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

###############################################################################
# Download the Colima binary.
###############################################################################
echo "[INFO] Downloading Colima..."

curl -fL "$DOWNLOAD_URL" -o "$COLIMA_BIN"

###############################################################################
# Make the binary executable.
###############################################################################
chmod +x "$COLIMA_BIN"

###############################################################################
# Ensure ~/.local/bin is present in ~/.zshrc.
###############################################################################
PATH_ENTRY='export PATH="$HOME/.local/bin:$PATH"'

if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

if ! grep -Fq "$PATH_ENTRY" "$HOME/.zshrc"; then
    {
        echo ""
        echo "# Added by Colima installer"
        echo "$PATH_ENTRY"
    } >> "$HOME/.zshrc"

    echo "[INFO] Added ~/.local/bin to PATH in ~/.zshrc."
else
    echo "[INFO] ~/.local/bin already exists in PATH."
fi

###############################################################################
# Export PATH for the current session.
###############################################################################
export PATH="$HOME/.local/bin:$PATH"

###############################################################################
# Source ~/.zshrc.
###############################################################################
if [ -f "$HOME/.zshrc" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.zshrc"
fi

###############################################################################
# Verify the installation.
###############################################################################
if command -v colima >/dev/null 2>&1; then
    echo "[INFO] Colima installed successfully."
    colima version
else
    echo "[ERROR] Colima installation failed."
    exit 1
fi

###############################################################################
# Installation completed.
###############################################################################
echo "[INFO] Colima installation completed successfully."
