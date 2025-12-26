#!/bin/bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# ----------------------
# This script installs Minikube on macOS Apple Silicon (ARM64).
# It performs the following actions:
# 1. Verifies the system architecture is ARM64 (Apple Silicon)
# 2. Creates a dedicated installation directory: $HOME/cli/minikube
# 3. Downloads the official Minikube ARM64 binary
# 4. Makes the binary executable
# 5. Installs Minikube into the target directory
# 6. Safely updates ~/.zshrc to add Minikube to PATH (no duplicates)
# 7. Reloads shell configuration
# 8. Verifies the installation
# 9. Cleans up all temporary and residual files automatically
#
# Note:
# - This script is strictly for macOS Apple Silicon (ARM64).
# - Intel (x86_64) systems are intentionally blocked.
###############################################################################

set -e  # Exit immediately if any command fails

############################
# Variables
############################
INSTALL_DIR="$HOME/cli/minikube"
TMP_DIR="$(mktemp -d)"
MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64"
MINIKUBE_BINARY="$TMP_DIR/minikube"
ZSHRC_FILE="$HOME/.zshrc"
PATH_ENTRY='export PATH="$HOME/cli/minikube:$PATH"'

############################
# Architecture validation
############################
ARCH=$(uname -m)

if [[ "$ARCH" != "arm64" ]]; then
    echo "ERROR: This script is for macOS Apple Silicon (ARM64) only."
    echo "Detected architecture: $ARCH"
    exit 1
fi

############################
# Create installation directory
############################
# -p ensures the directory is created only if it doesn't exist
mkdir -p "$INSTALL_DIR"

############################
# Download Minikube binary
############################
# Download the ARM64 Minikube binary to a temporary directory
curl -L "$MINIKUBE_URL" -o "$MINIKUBE_BINARY"

############################
# Make binary executable
############################
chmod +x "$MINIKUBE_BINARY"

############################
# Move binary to final location
############################
mv "$MINIKUBE_BINARY" "$INSTALL_DIR/minikube"

############################
# Configure PATH (idempotent)
############################
# Add Minikube path only if it does not already exist
if ! grep -Fxq "$PATH_ENTRY" "$ZSHRC_FILE"; then
    echo "" >> "$ZSHRC_FILE"
    echo "# Minikube CLI path" >> "$ZSHRC_FILE"
    echo "$PATH_ENTRY" >> "$ZSHRC_FILE"
fi

############################
# Reload shell configuration
############################
# shellcheck disable=SC1090
source "$ZSHRC_FILE"

############################
# Verify installation
############################
minikube version

############################
# Cleanup residual files
############################
# Remove the temporary directory and all downloaded artifacts
rm -rf "$TMP_DIR"

############################
# Completion message
############################
echo "Minikube installation completed successfully for Apple Silicon."
echo "Binary location: $INSTALL_DIR/minikube"
echo "PATH has been updated in ~/.zshrc"
