#!/bin/bash

###############################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs Colima on macOS.
# - Supports both Intel and Apple Silicon Macs.
# - Downloads the latest Colima release directly from GitHub.
# - Installs Colima into /usr/local/bin.
# - Verifies the installation.
# - Starts Colima automatically if it is not already running.
###############################################################################

# Exit immediately if a command fails.
set -e

###############################################################################
# Function: log_info
# Purpose:
# Prints informational messages.
###############################################################################
log_info() {
    echo "[INFO] $1"
}

###############################################################################
# Function: log_error
# Purpose:
# Prints error messages.
###############################################################################
log_error() {
    echo "[ERROR] $1"
}

###############################################################################
# Function: Detect CPU architecture
# Purpose:
# Determines whether the Mac is Intel or Apple Silicon.
###############################################################################
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    COLIMA_ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    COLIMA_ARCH="amd64"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

log_info "Detected architecture: $ARCH"

###############################################################################
# Function: Get latest Colima version
# Purpose:
# Retrieves the latest release tag from GitHub.
###############################################################################
log_info "Fetching latest Colima version..."

LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/abiosoft/colima/releases/latest | \
    grep '"tag_name"' | \
    cut -d '"' -f 4)

if [[ -z "$LATEST_VERSION" ]]; then
    log_error "Unable to determine latest Colima version."
    exit 1
fi

log_info "Latest version: $LATEST_VERSION"

###############################################################################
# Function: Build download URL
# Purpose:
# Creates the appropriate download URL based on architecture.
###############################################################################
DOWNLOAD_URL="https://github.com/abiosoft/colima/releases/download/${LATEST_VERSION}/colima-${COLIMA_ARCH}"

log_info "Download URL:"
echo "$DOWNLOAD_URL"

###############################################################################
# Function: Download Colima binary
# Purpose:
# Downloads the Colima executable.
###############################################################################
TEMP_FILE="/tmp/colima"

log_info "Downloading Colima..."

curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"

###############################################################################
# Function: Make binary executable
# Purpose:
# Grants execute permission.
###############################################################################
chmod +x "$TEMP_FILE"

###############################################################################
# Function: Install binary
# Purpose:
# Copies Colima to /usr/local/bin.
###############################################################################
INSTALL_DIR="/usr/local/bin"

if [[ ! -d "$INSTALL_DIR" ]]; then
    sudo mkdir -p "$INSTALL_DIR"
fi

log_info "Installing Colima to $INSTALL_DIR..."

sudo mv "$TEMP_FILE" "${INSTALL_DIR}/colima"

###############################################################################
# Function: Verify installation
# Purpose:
# Confirms Colima is installed correctly.
###############################################################################
if command -v colima >/dev/null 2>&1; then
    log_info "Colima installed successfully."
    colima version
else
    log_error "Colima installation failed."
    exit 1
fi

###############################################################################
# Function: Start Colima
# Purpose:
# Starts the Colima virtual machine if not already running.
###############################################################################
if ! colima status >/dev/null 2>&1; then
    log_info "Starting Colima..."
    colima start
else
    log_info "Colima is already running."
fi

###############################################################################
# Installation completed
###############################################################################
log_info "Colima installation completed successfully."
