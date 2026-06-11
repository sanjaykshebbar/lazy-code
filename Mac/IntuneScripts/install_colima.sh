#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima.
# - Supports both Intel and Apple Silicon Macs.
# - Designed for Intune deployment (runs as root).
# - Performs all user-specific operations as the logged-in standard user.
# - Installs Colima into ~/.local/bin.
# - Updates ~/.zshrc.
# - Ensures proper ownership.
# - Verifies the installation.
###############################################################################

###############################################################################
# Exit immediately if a command fails.
###############################################################################
set -e

###############################################################################
# Determine the currently logged-in user.
###############################################################################
CURRENT_USER=$(stat -f "%Su" /dev/console)

if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    echo "[ERROR] Unable to determine the logged-in user."
    exit 1
fi

echo "[INFO] Logged-in user: $CURRENT_USER"

###############################################################################
# Determine the user's home directory.
###############################################################################
USER_HOME=$(dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory | awk '{print $2}')

LOCAL_BIN="$USER_HOME/.local/bin"
COLIMA_BIN="$LOCAL_BIN/colima"
ZSHRC="$USER_HOME/.zshrc"

###############################################################################
# Detect CPU architecture.
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
# Create .local/bin directory.
###############################################################################
mkdir -p "$LOCAL_BIN"

###############################################################################
# Ensure ownership belongs to the standard user.
###############################################################################
chown -R "$CURRENT_USER":staff "$USER_HOME/.local"

###############################################################################
# Download Colima.
###############################################################################
echo "[INFO] Downloading Colima..."

curl -fL "$DOWNLOAD_URL" -o "$COLIMA_BIN"

###############################################################################
# Make the binary executable.
###############################################################################
chmod 755 "$COLIMA_BIN"

###############################################################################
# Ensure ownership of the binary.
###############################################################################
chown "$CURRENT_USER":staff "$COLIMA_BIN"

###############################################################################
# Create .zshrc if necessary.
###############################################################################
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
    chown "$CURRENT_USER":staff "$ZSHRC"
fi

###############################################################################
# Add ~/.local/bin to PATH if missing.
###############################################################################
PATH_ENTRY='export PATH="$HOME/.local/bin:$PATH"'

if ! grep -Fxq "$PATH_ENTRY" "$ZSHRC"; then
    {
        echo ""
        echo "# Added by Colima installer"
        echo "$PATH_ENTRY"
    } >> "$ZSHRC"
fi

###############################################################################
# Ensure .zshrc ownership.
###############################################################################
chown "$CURRENT_USER":staff "$ZSHRC"

###############################################################################
# Source .zshrc under the standard user's context.
###############################################################################
sudo -u "$CURRENT_USER" zsh -c "
export HOME='$USER_HOME'
source ~/.zshrc
"

###############################################################################
# Verify the installation under the standard user's context.
###############################################################################
sudo -u "$CURRENT_USER" env HOME="$USER_HOME" PATH="$LOCAL_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
"$COLIMA_BIN" version

###############################################################################
# Installation complete.
###############################################################################
echo "[INFO] Colima installation completed successfully."

echo "[INFO] Installed at:"
echo "       $COLIMA_BIN"

echo "[INFO] PATH updated in:"
echo "       $ZSHRC"
