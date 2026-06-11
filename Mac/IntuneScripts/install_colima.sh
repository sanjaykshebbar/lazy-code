#!/bin/sh

###############################################################################
# Author - Sanjay KS
# Email - sanjayks@zeta.tech
# GitHub - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs the latest version of Colima on macOS.
# - Supports both Intel and Apple Silicon Macs.
# - Automatically determines the latest release from GitHub.
# - Downloads the correct binary archive.
# - Extracts and installs the Colima binary.
# - Verifies the installation.
###############################################################################

###############################################################################
# Exit immediately if any command fails.
###############################################################################
set -e

###############################################################################
# Function:
# Print informational messages.
###############################################################################
log_info() {
    echo "[INFO] $1"
}

###############################################################################
# Function:
# Print error messages.
###############################################################################
log_error() {
    echo "[ERROR] $1"
}

###############################################################################
# Determine system architecture.
###############################################################################
ARCH="$(uname -m)"

case "$ARCH" in
    arm64)
        COLIMA_ARCH="arm64"
        ;;
    x86_64)
        COLIMA_ARCH="x86_64"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log_info "Detected architecture: $ARCH"

###############################################################################
# Retrieve the latest release tag from GitHub.
###############################################################################
LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/abiosoft/colima/releases/latest \
    | grep '"tag_name"' \
    | cut -d '"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    log_error "Unable to determine the latest Colima version."
    exit 1
fi

log_info "Latest version detected: $LATEST_VERSION"

###############################################################################
# Build download URL.
###############################################################################
DOWNLOAD_URL="https://github.com/abiosoft/colima/releases/download/${LATEST_VERSION}/colima-Darwin-${COLIMA_ARCH}.tar.gz"

log_info "Download URL:"
echo "$DOWNLOAD_URL"

###############################################################################
# Create a temporary directory.
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
# Install the binary.
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
# Installation completed.
###############################################################################
log_info "Installation completed successfully."
