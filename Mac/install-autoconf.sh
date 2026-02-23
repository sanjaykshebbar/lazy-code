#!/bin/bash

###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# ----------------------
# This script installs GNU Autoconf from source into a user-level directory
# ($HOME/.local/bin/autoconf) on macOS.
#
# Key features:
# - Does NOT use Homebrew
# - Does NOT require sudo/root access
# - Compiles Autoconf locally using system tools
# - Installs to $HOME/.local
# - Updates PATH safely via ~/.zshrc or ~/.bashrc
###############################################################################

set -e

# -----------------------------
# Variables
# -----------------------------
PREFIX="$HOME/.local"
BIN_DIR="$PREFIX/bin"
SRC_DIR="$HOME/Clitools/sources"
AUTOCONF_URL="http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz"
TAR_FILE="autoconf-latest.tar.gz"

# -----------------------------
# Detect shell profile
# -----------------------------
if [[ "$SHELL" == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.bashrc"
fi

# -----------------------------
# Pre-flight checks
# -----------------------------
echo "==> Checking required tools"

for cmd in curl tar make m4; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found."
        echo "Please ensure Xcode Command Line Tools are installed (xcode-select --install)."
        exit 1
    fi
done

# -----------------------------
# Create directory structure
# -----------------------------
echo "==> Creating directory structure"
mkdir -p "$BIN_DIR"
mkdir -p "$SRC_DIR"

# -----------------------------
# Download Autoconf source
# -----------------------------
echo "==> Downloading Autoconf source"
cd "$SRC_DIR"

curl -fL "$AUTOCONF_URL" -o "$TAR_FILE"

# -----------------------------
# Extract source
# -----------------------------
echo "==> Extracting Autoconf source"
tar -xzf "$TAR_FILE"
# Find the extracted directory name
EXTRACTED_DIR=$(tar -tf "$TAR_FILE" | head -1 | cut -f1 -d"/")
cd "$EXTRACTED_DIR"

# -----------------------------
# Configure and Install
# -----------------------------
echo "==> Configuring Autoconf (prefix=$PREFIX)"
./configure --prefix="$PREFIX"

echo "==> Compiling Autoconf"
make

echo "==> Installing Autoconf"
make install

# -----------------------------
# Update PATH if needed
# -----------------------------
if ! grep -q "$BIN_DIR" "$PROFILE_FILE" 2>/dev/null; then
    echo "==> Updating PATH in $PROFILE_FILE"
    echo "" >> "$PROFILE_FILE"
    echo "# Autoconf bin directory" >> "$PROFILE_FILE"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$PROFILE_FILE"
else
    echo "PATH already contains $BIN_DIR"
fi

# -----------------------------
# Cleanup
# -----------------------------
echo "==> Cleaning up source files"
cd "$SRC_DIR"
rm -rf "$EXTRACTED_DIR" "$TAR_FILE"

# -----------------------------
# Verify installation
# -----------------------------
echo "==> Verifying Autoconf installation"
"$BIN_DIR/autoconf" --version | head -n 1

# -----------------------------
# Final instructions
# -----------------------------
echo ""
echo "===================================================="
echo "Autoconf installation completed successfully"
echo ""
echo "Install location : $PREFIX"
echo "Binary location  : $BIN_DIR/autoconf"
echo ""
echo "Reload your shell or run:"
echo "source $PROFILE_FILE"
echo "===================================================="
