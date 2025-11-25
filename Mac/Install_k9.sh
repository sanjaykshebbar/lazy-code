#!/bin/bash

set -e

echo "=========================================="
echo "     K9s Installation (No Homebrew)"
echo "     macOS Intel + Apple Silicon"
echo "=========================================="

ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    PLATFORM="Darwin_arm64"
    echo "[INFO] Detected Apple Silicon (ARM64)"
else
    PLATFORM="Darwin_amd64"
    echo "[INFO] Detected Intel (x86_64)"
fi

CLITOOLS_DIR="$HOME/Clitools"
K9S_DIR="$CLITOOLS_DIR/k9s"
TMP_DIR="/tmp/k9s_install"

mkdir -p "$K9S_DIR"
mkdir -p "$TMP_DIR"

cd "$TMP_DIR"

echo "[1/5] Fetching latest K9s version..."

LATEST_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | grep tag_name | cut -d '"' -f4)

if [[ -z "$LATEST_VERSION" ]]; then
    echo "ERROR: Could not fetch latest version!"
    exit 1
fi

echo "Latest Version: $LATEST_VERSION"

# CORRECT FILENAME FORMAT: k9s_Darwin_amd64.tar.gz
K9S_TAR="k9s_${PLATFORM}.tar.gz"

# CORRECT DOWNLOAD URL FORMAT:
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${LATEST_VERSION}/${K9S_TAR}"

echo "[2/5] Downloading from:"
echo "$DOWNLOAD_URL"

curl -L -o "$K9S_TAR" "$DOWNLOAD_URL"

echo "[3/5] Extracting..."
tar -xzf "$K9S_TAR"

echo "[4/5] Installing..."
mv k9s "$K9S_DIR/k9s"
chmod +x "$K9S_DIR/k9s"

cd /
rm -rf "$TMP_DIR"

# Add to PATH if not already added
if ! grep -q 'export PATH="$HOME/Clitools/k9s:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/Clitools/k9s:$PATH"' >> ~/.zshrc
fi

echo
echo "Run: source ~/.zshrc"
echo
echo "=========================================="
echo " K9s Installed Successfully!"
echo " Version: $($K9S_DIR/k9s version)"
echo " Location: $K9S_DIR/k9s"
echo "=========================================="
