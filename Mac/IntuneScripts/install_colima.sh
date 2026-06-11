#!/bin/bash

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest Colima release system-wide.
# - Supports Intel and Apple Silicon Macs.
# - Installs into /usr/local/bin.
# - Suitable for execution via Intune (root).
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

echo "[INFO] Downloading Colima..."

TMP_FILE=$(mktemp)

curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE"

chmod +x "$TMP_FILE"

mkdir -p /usr/local/bin

mv "$TMP_FILE" /usr/local/bin/colima

chmod 755 /usr/local/bin/colima

echo "[INFO] Verifying installation..."

/usr/local/bin/colima version

echo "[INFO] Colima installation completed successfully."
