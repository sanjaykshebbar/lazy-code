#!/bin/bash
set -e

INSTALL_DIR="$HOME/cli/hugo"
BIN_PATH="$INSTALL_DIR/hugo"
ZSHRC="$HOME/.zshrc"

echo "===== HUGO INSTALL START ====="

ARCH="$(uname -m)"
echo "Detected architecture: $ARCH"

if [[ "$ARCH" == "arm64" ]]; then
    HUGO_ARCH="macOS-ARM64"
elif [[ "$ARCH" == "x86_64" ]]; then
    HUGO_ARCH="macOS-64bit"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Get latest version
LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/gohugoio/hugo/releases/latest | \
    grep '"tag_name"' | cut -d '"' -f 4)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch latest version"
    exit 1
fi

echo "Latest Hugo version: $LATEST_VERSION"

VERSION_CLEAN="${LATEST_VERSION#v}"
TAR_FILE="hugo_extended_${VERSION_CLEAN}_${HUGO_ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/${LATEST_VERSION}/${TAR_FILE}"

mkdir -p "$INSTALL_DIR"

echo "Downloading: $DOWNLOAD_URL"

curl -fL "$DOWNLOAD_URL" -o "/tmp/$TAR_FILE"

echo "Extracting..."
tar -xzf "/tmp/$TAR_FILE" -C "$INSTALL_DIR"

rm -f "/tmp/$TAR_FILE"

chmod +x "$BIN_PATH"

# Add to PATH if missing
if ! grep -q 'export PATH="$HOME/cli/hugo:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/cli/hugo:$PATH"' >> "$ZSHRC"
fi

# Reload zsh config safely
if [ -n "$ZSH_VERSION" ]; then
    source "$ZSHRC"
fi

echo "Installed Hugo version:"
"$BIN_PATH" version

echo "===== HUGO INSTALL COMPLETE ====="
