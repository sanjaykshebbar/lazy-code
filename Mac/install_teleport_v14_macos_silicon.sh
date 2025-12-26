#!/bin/bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# -----------------------------------------------------------------------------
# This script installs Teleport (tsh client) version 14 on macOS Silicon (ARM64).
# - Downloads the official Teleport v14 macOS ARM64 archive
# - Extracts ONLY the tsh binary
# - Installs tsh into $HOME/clitools/tsh
# - Removes all temporary files automatically
# - Updates ~/.zshrc to make this tsh the default Teleport client
# - Verifies the installation
#
# NOTE:
# - No Homebrew is used
# - Installation is user-level only
# - Safe to re-run (idempotent)
###############################################################################

set -e  # Exit immediately if any command fails

# ----------------------------- VARIABLES -------------------------------------
TELEPORT_VERSION="14.3.2"
OS="darwin"
ARCH="arm64"

INSTALL_BASE="$HOME/clitools"
INSTALL_DIR="$INSTALL_BASE/tsh"
TMP_DIR="$(mktemp -d)"

DOWNLOAD_URL="https://cdn.teleport.dev/teleport-v${TELEPORT_VERSION}-${OS}-${ARCH}-bin.tar.gz"
ARCHIVE_NAME="teleport.tar.gz"

ZSHRC_FILE="$HOME/.zshrc"

# ----------------------------- PRE-CHECKS ------------------------------------
echo "▶ Checking macOS architecture..."
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "❌ This script is ONLY for macOS Silicon (ARM64)"
  exit 1
fi

# ----------------------------- SETUP DIRS ------------------------------------
echo "▶ Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# ----------------------------- DOWNLOAD --------------------------------------
echo "▶ Downloading Teleport v${TELEPORT_VERSION} (macOS ARM64)..."
curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/$ARCHIVE_NAME"

# ----------------------------- EXTRACT ---------------------------------------
echo "▶ Extracting tsh binary..."
tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"

# Find tsh binary dynamically (future-proof)
TSH_BINARY_PATH="$(find "$TMP_DIR" -type f -name tsh | head -n 1)"

if [[ -z "$TSH_BINARY_PATH" ]]; then
  echo "❌ tsh binary not found after extraction"
  exit 1
fi

# ----------------------------- INSTALL ---------------------------------------
echo "▶ Installing tsh to $INSTALL_DIR"
cp "$TSH_BINARY_PATH" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/tsh"

# ----------------------------- CLEANUP ---------------------------------------
echo "▶ Cleaning up temporary files"
rm -rf "$TMP_DIR"

# ----------------------------- PATH SETUP ------------------------------------
echo "▶ Configuring PATH in ~/.zshrc"

PATH_ENTRY='export PATH="$HOME/clitools/tsh:$PATH"'

if ! grep -Fxq "$PATH_ENTRY" "$ZSHRC_FILE"; then
  echo "" >> "$ZSHRC_FILE"
  echo "# Teleport (tsh) CLI" >> "$ZSHRC_FILE"
  echo "$PATH_ENTRY" >> "$ZSHRC_FILE"
  echo "✔ PATH updated in ~/.zshrc"
else
  echo "ℹ PATH already configured"
fi

# ----------------------------- VERIFY ----------------------------------------
echo "▶ Reloading shell configuration"
source "$ZSHRC_FILE"

echo "▶ Verifying installation..."
tsh version

echo "✅ Teleport tsh v${TELEPORT_VERSION} installed successfully"
echo "📍 Binary location: $INSTALL_DIR/tsh"
