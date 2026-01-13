#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Downloads Teleport v14 tsh binary for macOS (Intel or Apple Silicon)
# - Installs it into $HOME/cli/tsh
# - Forces this tsh to take priority over any other tsh installed on the system
# - Updates PATH in ~/.zshrc or ~/.bashrc
# - Does not use sudo and does not use Homebrew
###############################################################################

set -e

# ----------------------------- #
# Configuration                 #
# ----------------------------- #

TELEPORT_VERSION="14.3.5"   # pin to Teleport 14.x
INSTALL_DIR="$HOME/cli/tsh"
BIN_DIR="$INSTALL_DIR/bin"
TMP_DIR="$(mktemp -d)"

# ----------------------------- #
# Architecture detection        #
# ----------------------------- #

ARCH="$(uname -m)"
case "$ARCH" in
  arm64)
    TELEPORT_ARCH="darwin-arm64"
    ;;
  x86_64)
    TELEPORT_ARCH="darwin-amd64"
    ;;
  *)
    echo "ERROR: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

TAR_NAME="teleport-v${TELEPORT_VERSION}-${TELEPORT_ARCH}.tar.gz"
DOWNLOAD_URL="https://cdn.teleport.dev/${TAR_NAME}"

# ----------------------------- #
# Pre-flight checks             #
# ----------------------------- #

for cmd in curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: Required command '$cmd' not found."
    exit 1
  }
done

mkdir -p "$BIN_DIR"

# ----------------------------- #
# Download Teleport             #
# ----------------------------- #

echo "Downloading Teleport v${TELEPORT_VERSION} (${TELEPORT_ARCH})..."
cd "$TMP_DIR"
curl -fLO "$DOWNLOAD_URL"

# ----------------------------- #
# Extract                       #
# ----------------------------- #

echo "Extracting tsh..."
tar -xzf "$TAR_NAME"

# Teleport tarball contains a directory like teleport/
cp teleport/tsh "$BIN_DIR/"
chmod +x "$BIN_DIR/tsh"

# ----------------------------- #
# Cleanup                       #
# ----------------------------- #

rm -rf "$TMP_DIR"

# ----------------------------- #
# Shell PATH handling           #
# ----------------------------- #

# Detect shell rc file
if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.profile"
fi

# Force precedence: prepend path
if ! grep -q "$BIN_DIR" "$RC"; then
  echo "" >> "$RC"
  echo "# Teleport tsh v14 (user-space, forced precedence)" >> "$RC"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$RC"
fi

# Apply to current shell
export PATH="$BIN_DIR:$PATH"

# ----------------------------- #
# Hard override safety          #
# ----------------------------- #

# Warn if other tsh binaries exist
OTHER_TSH="$(command -v tsh || true)"
if [[ "$OTHER_TSH" != "$BIN_DIR/tsh" ]]; then
  echo "NOTE: Other tsh detected at: $OTHER_TSH"
  echo "This installation takes precedence via PATH ordering."
fi

# ----------------------------- #
# Verification                  #
# ----------------------------- #

echo "Verification:"
which tsh
tsh version

echo "Teleport tsh v14 installed successfully at $BIN_DIR/tsh"
