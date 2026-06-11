#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest Colima release.
# - Supports Intel and Apple Silicon Macs.
# - Downloads the correct binary.
# - Installs it into /usr/local/bin.
# - Verifies the installation.
###############################################################################

set -e

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

TMP_FILE=$(mktemp)

echo "[INFO] Downloading Colima..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE"

chmod +x "$TMP_FILE"

echo "[INFO] Installing Colima..."
sudo mkdir -p /usr/local/bin
sudo mv "$TMP_FILE" /usr/local/bin/colima

echo "[INFO] Verifying installation..."
/usr/local/bin/colima version

echo "[INFO] Colima installation completed successfully."
