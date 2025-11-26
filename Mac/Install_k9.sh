#!/bin/zsh

set -e

# Detect Mac architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    K9S_ARCH="Darwin_amd64"
elif [ "$ARCH" = "arm64" ]; then
    K9S_ARCH="Darwin_arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $K9S_ARCH"

# Fetch latest release version
LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep tag_name | cut -d '"' -f4)

if [ -z "$LATEST" ]; then
    echo "Failed to fetch latest version."
    exit 1
fi

echo "Latest K9s version: $LATEST"

# Correct download URL
K9S_URL="https://github.com/derailed/k9s/releases/download/${LATEST}/k9s_${K9S_ARCH}.tar.gz"

# Temp workspace
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

echo "Downloading: $K9S_URL"
curl -L -o k9s.tar.gz "$K9S_URL"

# Verify file is actually a gzip archive
if ! file k9s.tar.gz | grep -q "gzip compressed data"; then
    echo "Downloaded file is not a valid tar.gz. Aborting."
    exit 1
fi

echo "Extracting..."
tar -xzf k9s.tar.gz

# Install location
TARGET_DIR="$HOME/Clitools/k9s"
mkdir -p "$TARGET_DIR"

mv k9s "$TARGET_DIR/"
chmod +x "$TARGET_DIR/k9s"

echo "Installed to $TARGET_DIR/k9s"

# Update PATH in .zshrc
ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/Clitools/k9s:$PATH"'

if ! grep -q "Clitools/k9s" "$ZSHRC"; then
    echo "\n# Added by k9s installer" >> "$ZSHRC"
    echo "$PATH_LINE" >> "$ZSHRC"
    echo "Updated .zshrc"
fi

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Done. Run: source ~/.zshrc"
