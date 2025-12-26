#!/bin/bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# ----------------------
# This script installs Minikube on a macOS Intel (x86_64) system.
# It performs the following actions:
# 1. Verifies the system architecture is Intel (x86_64)
# 2. Creates a dedicated installation directory: $HOME/cli/minikube
# 3. Downloads the official Minikube Intel binary
# 4. Makes the binary executable
# 5. Verifies the installation
# 6. Cleans up all temporary and residual files automatically
#
# Note:
# - This script is strictly for macOS Intel machines.
# - Apple Silicon (ARM64) is intentionally blocked.
###############################################################################

set -e  # Exit immediately if any command fails

############################
# Variables
############################
INSTALL_DIR="$HOME/cli/minikube"
TMP_DIR="$(mktemp -d)"
MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64"
MINIKUBE_BINARY="$TMP_DIR/minikube"

############################
# Architecture validation
############################
ARCH=$(uname -m)

if [[ "$ARCH" != "x86_64" ]]; then
    echo "ERROR: This script is for macOS Intel (x86_64) only."
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
# Download the Intel-specific Minikube binary to a temporary directory
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
# Verify installation
############################
"$INSTALL_DIR/minikube" version

############################
# Cleanup residual files
############################
# Remove the temporary directory and all downloaded artifacts
rm -rf "$TMP_DIR"

############################
# Completion message
############################
echo "Minikube installation completed successfully."
echo "Binary location: $INSTALL_DIR/minikube"
echo "Add this to your PATH if not already present:"
echo "export PATH=\"\$HOME/cli/minikube:\$PATH\""
