#!/bin/bash
set -e

INSTALL_DIR="$HOME/cli/hugo"
ZSHRC="$HOME/.zshrc"

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    MATCH="macOS-ARM64.tar.gz"
elif [[ "$ARCH" == "x86_64" ]]; then
    MATCH="macOS-64bit.tar.gz"
else
    echo "Unsupported architecture"
    exit 1
fi

echo "Fetching latest release metadata..."

ASSET_URL=$(curl -fsSL https://api.github.com/repos/gohugoio/hugo/releases/latest \
  | grep browser_download_url \
  | grep "$MATCH" \
  | grep extended \
  | cut -d '"' -f 4 \
  | head -n 1)

if [ -z "$ASSET_URL" ]; then
    echo "Failed to locate correct Hugo asset"
    exit 1
fi

echo "Downloading: $ASSET_URL"

mkdir -p "$INSTALL_DIR"

curl -fL "$ASSET_URL" -o /tmp/hugo.tar.gz
tar -xzf /tmp/hugo.tar.gz -C "$INSTALL_DIR"
rm /tmp/hugo.tar.gz

chmod +x "$INSTALL_DIR/hugo"

if ! grep -q 'export PATH="$HOME/cli/hugo:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/cli/hugo:$PATH"' >> "$ZSHRC"
fi

source "$ZSHRC"

"$INSTALL_DIR/hugo" version
