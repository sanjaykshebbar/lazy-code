#!/bin/sh

###############################################################################
# Author - Sanjay KS
# Email - sanjaykshebbar@gmail.com
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima.
# - Supports Intel and Apple Silicon Macs.
# - Downloads the correct binary from GitHub Releases.
# - Installs Colima into /usr/local/bin.
###############################################################################

set -e

###############################################################################
# Determine architecture.
###############################################################################
ARCH=$(uname -m)

case "$ARCH" in
    arm64)
        ASSET_NAME="colima-Darwin-arm64"
        ;;
    x86_64)
        ASSET_NAME="colima-Darwin-x86_64"
        ;;
    *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "[INFO] Architecture: $ARCH"

###############################################################################
# Determine latest version.
###############################################################################
LATEST_VERSION=$(curl -fsSL \
https://api.github.com/repos/abiosoft/colima/releases/latest \
| awk -F'"' '/tag_name/{print $4}')

if [ -z "$LATEST_VERSION" ]; then
    echo "[ERROR] Failed to determine latest version."
    exit 1
fi

echo "[INFO] Latest version: $LATEST_VERSION"

###############################################################################
# Build download URL.
###############################################################################
DOWNLOAD_URL="https://github.com/abiosoft/colima/releases/download/${LATEST_VERSION}/${ASSET_NAME}"

echo "[INFO] Download URL:"
echo "$DOWNLOAD_URL"

###############################################################################
# Download binary.
###############################################################################
TMP_FILE=$(mktemp)

curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE"

###############################################################################
# Install Colima.
###############################################################################
sudo install -m 755 "$TMP_FILE" /usr/local/bin/colima

rm -f "$TMP_FILE"

###############################################################################
# Verify installation.
###############################################################################
echo "[INFO] Installed version:"
colima version
