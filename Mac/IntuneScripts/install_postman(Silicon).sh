#!/bin/bash

###############################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Detects whether the Mac is Intel or Apple Silicon.
# - Downloads the latest Postman package for the detected architecture.
# - Removes any existing Postman installation.
# - Extracts and installs Postman into /Applications.
# - Sets appropriate permissions.
# - Cleans up temporary files.
# - Launches Postman after installation.
###############################################################################

# Exit immediately if a command exits with a non-zero status
set -e

###############################################################################
# Define temporary locations
###############################################################################
TMP_ZIP="/tmp/Postman.zip"
TMP_DIR="/tmp/Postman"

###############################################################################
# Detect CPU architecture and determine download URL
###############################################################################
ARCH=$(uname -m)

case "$ARCH" in
    arm64)
        echo "Apple Silicon Mac detected."
        POSTMAN_URL="https://dl.pstmn.io/download/latest/osx_arm64"
        ;;
    x86_64)
        echo "Intel Mac detected."
        POSTMAN_URL="https://dl.pstmn.io/download/latest/osx_64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

###############################################################################
# Remove old temporary files
###############################################################################
rm -rf "$TMP_ZIP"
rm -rf "$TMP_DIR"

###############################################################################
# Download the latest Postman package
###############################################################################
echo "Downloading Postman..."

curl -fsSL "$POSTMAN_URL" -o "$TMP_ZIP"

###############################################################################
# Extract the downloaded archive
###############################################################################
echo "Extracting package..."

unzip -q "$TMP_ZIP" -d "$TMP_DIR"

###############################################################################
# Remove existing Postman installation if present
###############################################################################
if [ -d "/Applications/Postman.app" ]; then
    echo "Removing existing Postman installation..."
    rm -rf "/Applications/Postman.app"
fi

###############################################################################
# Install Postman
###############################################################################
echo "Installing Postman..."

cp -R "$TMP_DIR/Postman.app" "/Applications/"

###############################################################################
# Set ownership and permissions
###############################################################################
chown -R root:wheel "/Applications/Postman.app"
chmod -R 755 "/Applications/Postman.app"

###############################################################################
# Remove temporary files
###############################################################################
rm -rf "$TMP_ZIP"
rm -rf "$TMP_DIR"

###############################################################################
# Launch Postman
###############################################################################
echo "Launching Postman..."
open "/Applications/Postman.app"

echo "Postman installation completed successfully."
