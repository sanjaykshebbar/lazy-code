#!/bin/sh

###############################################################################
# Author - Sanjay KS
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima on macOS.
# - Supports both Intel and Apple Silicon Macs.
# - Retrieves the latest release information from GitHub.
# - Downloads the appropriate archive for the detected architecture.
# - Extracts and installs the Colima binary into /usr/local/bin.
# - Verifies the installation.
###############################################################################

###############################################################################
# Exit immediately if a command fails.
###############################################################################
set -e

###############################################################################
# Function:
# Display informational messages.
###############################################################################
log_info() {
    echo "[INFO] $1"
}

###############################################################################
# Function:
# Display error messages.
###############################################################################
log_error() {
    echo "[ERROR] $1"
}

###############################################################################
# Determine system architecture.
###############################################################################
ARCH=$(uname -m)

case "$ARCH" in
    arm64)
        ASSET_NAME="colima-Darwin-arm64.tar.gz"
        ;;
    x86_64)
        ASSET_NAME="colima-Darwin-x86_64.tar.gz"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log_info "Detected architecture: $ARCH"

###############################################################################
# Retrieve the download URL for the latest release.
###############################################################################
log_info "Retrieving latest Colima release information..."

DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/abiosoft/colima/releases/latest \
    | grep browser_download_url \
    | grep "$ASSET_NAME" \
    | cut -d '"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    log_error "Unable to determine the download URL."
    exit 1
fi

log_info "Download URL:"
echo "$DOWNLOAD_URL"

###############################################################################
# Create temporary directory.
###############################################################################
TEMP_DIR=$(mktemp -d)

###############################################################################
# Download the archive.
###############################################################################
log_info "Downloading Colima..."

curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/colima.tar.gz"

###############################################################################
# Extract the archive.
###############################################################################
log_info "Extracting archive..."

tar -xzf "$TEMP_DIR/colima.tar.gz" -C "$TEMP_DIR"

###############################################################################
# Ensure installation directory exists.
###############################################################################
if [ ! -d "/usr/local/bin" ]; then
    sudo mkdir -p /usr/local/bin
fi

###############################################################################
# Install Colima binary.
###############################################################################
log_info "Installing Colima..."

sudo mv "$TEMP_DIR/colima" /usr/local/bin/colima
sudo chmod +x /usr/local/bin/colima

###############################################################################
# Remove temporary files.
###############################################################################
rm -rf "$TEMP_DIR"

###############################################################################
# Verify installation.
###############################################################################
if command -v colima >/dev/null 2>&1; then
    log_info "Colima installed successfully."
    colima version
else
    log_error "Colima installation failed."
    exit 1
fi

###############################################################################
# Finished.
###############################################################################
log_info "Installation completed successfully."
