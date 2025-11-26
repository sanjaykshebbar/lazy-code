#!/bin/zsh

set -e

# Detect Mac architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    K9S_ARCH="Darwin_x86_64"
elif [ "$ARCH" = "arm64" ]; then
    K9S_ARCH="Darwin_arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $K9S_ARCH"

# Get latest K9s release version
LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep tag_name | cut -d '"' -f4)

if [ -z "$LATEST" ]; then
    echo "Failed to fetch latest K9s version."
    exit 1
fi

echo "Latest K9s version: $LATEST"

# Download URL
K9S_URL="https://github.com/derailed/k9s/releases/download/${LATEST}/k9s_${K9S_ARCH}.tar.gz"

# Temp download location
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

echo "Downloading K9s from: $K9S_URL"
curl -L -o k9s.tar.gz "$K9S_URL"

echo "Extracting..."
tar -xzf k9s.tar.gz

# Prepare target directory
TARGET_DIR="$HOME/Clitools/k9s"
mkdir -p "$TARGET_DIR"

# Move binary
mv k9s "$TARGET_DIR/"
chmod +x "$TARGET_DIR/k9s"

echo "K9s installed to: $TARGET_DIR/k9s"

# Update .zshrc if PATH entry missing
ZSHRC="$HOME/.zshrc"
K9S_PATH_CMD='export PATH="$HOME/Clitools/k9s:$PATH"'

if ! grep -q 'Clitools/k9s' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Added by K9s installer" >> "$ZSHRC"
    echo "$K9S_PATH_CMD" >> "$ZSHRC"
    echo "Updated .zshrc with K9s path."
else
    echo ".zshrc already contains K9s path. Skipping update."
fi

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Installation complete. Restart your terminal or run:"
echo "source ~/.zshrc"
