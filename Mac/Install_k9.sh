#!/bin/bash

set -e

echo "=========================================="
echo "     K9s Installation (No Homebrew)"
echo "     macOS Intel + Apple Silicon"
echo "=========================================="

# Detect architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    PLATFORM="Darwin_arm64"
    echo "[INFO] Detected Apple Silicon (ARM64)"
else
    PLATFORM="Darwin_x86_64"
    echo "[INFO] Detected Intel (x86_64)"
fi

# Paths
CLITOOLS_DIR="$HOME/Clitools"
K9S_DIR="$CLITOOLS_DIR/k9s"
TMP_DIR="/tmp/k9s_install"

mkdir -p "$K9S_DIR"
mkdir -p "$TMP_DIR"

cd "$TMP_DIR"

echo "[1/5] Fetching latest K9s version..."

# Fetch latest version from GitHub (jq-free)
LATEST_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f4)

if [[ -z "$LATEST_VERSION" ]]; then
    echo "ERROR: Unable to fetch latest K9s version!"
    exit 1
fi

echo "Latest K9s Version: $LATEST_VERSION"

# Build download URL
K9S_TAR="k9s_${LATEST_VERSION}_${PLATFORM}.tar.gz"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${LATEST_VERSION}/${K9S_TAR}"

echo "[2/5] Downloading K9s from:"
echo "$DOWNLOAD_URL"

curl -LO "$DOWNLOAD_URL"

echo "[3/5] Extracting K9s..."
tar -xzf "$K9S_TAR"

echo "[4/5] Installing K9s into $K9S_DIR..."
mv k9s "$K9S_DIR/k9s"
chmod +x "$K9S_DIR/k9s"

# Cleanup
cd /
rm -rf "$TMP_DIR"

# Add PATH if missing
if ! grep -q 'export PATH="$HOME/Clitools/k9s:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/Clitools/k9s:$PATH"' >> ~/.zshrc
fi

source ~/.zshrc || true

echo "=========================================="
echo "K9s Installation Complete!"
echo "Installed Version: $($K9S_DIR/k9s version)"
echo "Executable Path: $K9S_DIR/k9s"
echo "Run: k9s"
echo "=========================================="
