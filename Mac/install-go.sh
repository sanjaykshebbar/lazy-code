#!/bin/bash
set -e

########################################
# CONFIG
########################################
INSTALL_BASE="$HOME/.local"
GO_INSTALL_DIR="$INSTALL_BASE/go"
TMP_DIR="$HOME/.local/share/go-install"
ZSHRC="$HOME/.zshrc"

mkdir -p "$INSTALL_BASE" "$TMP_DIR"

########################################
# ARCH DETECTION
########################################
ARCH="$(uname -m)"

if [[ "$ARCH" == "arm64" ]]; then
    GO_ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    GO_ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

########################################
# FETCH LATEST VERSION
########################################
echo "Fetching latest Go version..."

GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)

if [[ -z "$GO_VERSION" ]]; then
    echo "Failed to determine latest Go version"
    exit 1
fi

echo "Latest Go version: $GO_VERSION"

ARCHIVE="${GO_VERSION}.darwin-${GO_ARCH}.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${ARCHIVE}"

########################################
# DOWNLOAD
########################################
echo "Downloading Go..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/go.tar.gz"

########################################
# CLEAN OLD INSTALL
########################################
rm -rf "$GO_INSTALL_DIR"

########################################
# EXTRACT
########################################
echo "Extracting..."
tar -C "$INSTALL_BASE" -xzf "$TMP_DIR/go.tar.gz"

rm -rf "$TMP_DIR"

########################################
# PATH SETUP
########################################
if ! grep -q 'export PATH="$HOME/.local/go/bin:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo '' >> "$ZSHRC"
    echo '# Go binary path' >> "$ZSHRC"
    echo 'export PATH="$HOME/.local/go/bin:$PATH"' >> "$ZSHRC"
fi

########################################
# LOAD PATH (CURRENT SESSION)
########################################
export PATH="$HOME/.local/go/bin:$PATH"

########################################
# VERIFY
########################################
if command -v go >/dev/null 2>&1; then
    echo "Go installed successfully:"
    go version
else
    echo "Go installation failed"
    exit 1
fi

echo "Installation complete."
