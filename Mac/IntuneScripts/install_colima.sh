#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima for the logged-in user.
# - Supports both Intel and Apple Silicon Macs.
# - Designed for execution via Intune (runs as root).
# - Installs Colima into the user's ~/.local/bin directory.
# - Updates the user's ~/.zshrc to include ~/.local/bin in PATH.
# - Ensures the user owns the ~/.local directory.
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

###############################################################################
# Determine the home directory of the logged-in user.
###############################################################################
USER_HOME=$(dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory | awk '{print $2}')

###############################################################################
# Define installation paths.
###############################################################################
LOCAL_BIN="$USER_HOME/.local/bin"
COLIMA_BIN="$LOCAL_BIN/colima"
ZSHRC="$USER_HOME/.zshrc"

###############################################################################
# Create the installation directory.
###############################################################################
mkdir -p "$LOCAL_BIN"

###############################################################################
# Ensure the user owns the .local directory.
###############################################################################
chown -R "$CURRENT_USER":staff "$USER_HOME/.local"

###############################################################################
# Detect the system architecture.
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
chmod 755 "$COLIMA_BIN"

###############################################################################
# Ensure ownership of the binary.
###############################################################################
chown "$CURRENT_USER":staff "$COLIMA_BIN"

###############################################################################
# Create .zshrc if it does not exist.
###############################################################################
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
    chown "$CURRENT_USER":staff "$ZSHRC"
fi

###############################################################################
# Define the PATH entry.
###############################################################################
PATH_ENTRY='export PATH="$HOME/.local/bin:$PATH"'

###############################################################################
# Add the PATH entry only if it does not already exist.
###############################################################################
if ! grep -Fq "$PATH_ENTRY" "$ZSHRC"; then
    {
        echo ""
        echo "# Added by Colima installer"
        echo "$PATH_ENTRY"
    } >> "$ZSHRC"
fi

###############################################################################
# Ensure ownership of the .zshrc file.
###############################################################################
chown "$CURRENT_USER":staff "$ZSHRC"

###############################################################################
# Verify the installation as the logged-in user.
###############################################################################
if sudo -u "$CURRENT_USER" "$COLIMA_BIN" version >/dev/null 2>&1; then
    echo "[INFO] Colima installed successfully."
    sudo -u "$CURRENT_USER" "$COLIMA_BIN" version
else
    echo "[ERROR] Colima installation failed."
    exit 1
fi

###############################################################################
# Inform the user.
###############################################################################
echo "[INFO] Colima installation completed successfully."
echo "[INFO] ~/.local/bin has been added to $ZSHRC."
echo "[INFO] The user may need to run:"
echo "       source ~/.zshrc"
echo "[INFO] or open a new terminal session."
