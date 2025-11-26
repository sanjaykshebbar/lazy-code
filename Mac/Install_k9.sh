#!/bin/zsh

# Variables
TARGET_DIR="$HOME/Clitools"
K9S_URL="https://github.com/derailed/k9s/releases/download/v0.50.16/k9s_Darwin_amd64.tar.gz"
TAR_FILE="$TARGET_DIR/k9s_Darwin_amd64.tar.gz"
ZSHRC="$HOME/.zshrc"

echo "Creating directory at $TARGET_DIR..."
mkdir -p "$TARGET_DIR"

echo "Downloading k9s..."
curl -L -o "$TAR_FILE" "$K9S_URL"

echo "Extracting k9s..."
tar -xzf "$TAR_FILE" -C "$TARGET_DIR"

echo "Cleaning up tar file..."
rm -f "$TAR_FILE"

# Check if PATH already exists in zshrc
if ! grep -q 'export PATH="$HOME/Clitools:$PATH"' "$ZSHRC"; then
    echo "Adding Clitools to PATH in .zshrc..."
    echo '\n# Added by k9s installer\nexport PATH="$HOME/Clitools:$PATH"' >> "$ZSHRC"
else
    echo "PATH entry already exists in .zshrc, skipping..."
fi

echo "Reloading zshrc..."
source "$ZSHRC"

echo "\n✅ k9s installation completed!"
echo "You can now run: k9s"
