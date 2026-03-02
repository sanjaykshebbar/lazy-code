#!/bin/bash
set -e

INSTALL_DIR="$HOME/cli/hugo"
BIN_PATH="$INSTALL_DIR/hugo"
ZSHRC="$HOME/.zshrc"

echo "===== HUGO INSTALL START ====="

# Detect architecture
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

# Get latest Hugo version
LATEST_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | \
    grep '"tag_name"' | cut -d '"' -f 4)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch latest version"
    exit 1
fi

echo "Latest Hugo version: $LATEST_VERSION"

TAR_FILE="hugo_${LATEST_VERSION#v}_${HUGO_ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/${LATEST_VERSION}/${TAR_FILE}"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download
echo "Downloading Hugo..."
curl -L "$DOWNLOAD_URL" -o "/tmp/$TAR_FILE"

# Extract
echo "Extracting Hugo..."
tar -xzf "/tmp/$TAR_FILE" -C "$INSTALL_DIR"

# Cleanup tar
rm -f "/tmp/$TAR_FILE"

# Ensure executable
chmod +x "$BIN_PATH"

# Add to PATH in .zshrc if not already present
if ! grep -q 'export PATH="$HOME/cli/hugo:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/cli/hugo:$PATH"' >> "$ZSHRC"
    echo "Added Hugo to PATH in ~/.zshrc"
fi

# Reload zshrc
source "$ZSHRC"

# Verify installation
if command -v hugo >/dev/null 2>&1; then
    echo "Hugo installed successfully:"
    hugo version
else
    echo "Installation failed."
    exit 1
fi

echo "===== HUGO INSTALL COMPLETE ====="
