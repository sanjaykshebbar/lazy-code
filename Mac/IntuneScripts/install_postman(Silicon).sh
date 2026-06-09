#!/bin/bash

###############################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Downloads the latest Postman package for Apple Silicon Macs.
# - Removes any existing Postman installation.
# - Extracts and installs Postman into /Applications.
# - Sets appropriate ownership and permissions.
# - Launches Postman automatically after installation.
###############################################################################

# Exit immediately if a command fails
set -e

###############################################################################
# Verify that the machine is Apple Silicon
###############################################################################
ARCH=$(uname -m)

if [[ "$ARCH" != "arm64" ]]; then
    echo "This script is intended only for Apple Silicon Macs."
    echo "Detected architecture: $ARCH"
    exit 1
fi

###############################################################################
# Define variables
###############################################################################
POSTMAN_URL="https://dl.pstmn.io/download/latest/osx_arm64"
TMP_FILE="/tmp/Postman.zip"
TMP_DIR="/tmp/Postman"

###############################################################################
# Remove temporary files if they already exist
###############################################################################
rm -rf "$TMP_FILE"
rm -rf "$TMP_DIR"

###############################################################################
# Download the latest Postman package
###############################################################################
echo "Downloading latest Postman..."

curl -L "$POSTMAN_URL" -o "$TMP_FILE"

###############################################################################
# Extract the downloaded ZIP file
###############################################################################
echo "Extracting Postman..."

unzip -q "$TMP_FILE" -d "$TMP_DIR"

###############################################################################
# Remove any existing Postman installation
###############################################################################
if [ -d "/Applications/Postman.app" ]; then
    echo "Removing existing Postman installation..."
    rm -rf "/Applications/Postman.app"
fi

###############################################################################
# Copy Postman to the Applications folder
###############################################################################
echo "Installing Postman..."

cp -R "$TMP_DIR/Postman.app" "/Applications/"

###############################################################################
# Set ownership and permissions
###############################################################################
chown -R root:wheel "/Applications/Postman.app"
chmod -R 755 "/Applications/Postman.app"

###############################################################################
# Cleanup temporary files
###############################################################################
rm -rf "$TMP_FILE"
rm -rf "$TMP_DIR"

###############################################################################
# Launch Postman
###############################################################################
echo "Launching Postman..."

open "/Applications/Postman.app"

echo "Postman installation completed successfully."
