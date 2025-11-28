#!/bin/sh

ARCH=$(uname -m)

# Detect architecture and set download URL
if [ "$ARCH" = "arm64" ]; then
    echo "Detected Mac Type: Apple Silicon (ARM64)"
    DOWNLOAD_URL="https://get.helm.sh/helm-v3.15.4-darwin-arm64.tar.gz"
else
    echo "Detected Mac Type: Intel (x86_64)"
    DOWNLOAD_URL="https://get.helm.sh/helm-v3.15.4-darwin-amd64.tar.gz"
fi

echo "Downloading Helm from: $DOWNLOAD_URL"
curl -L -o helm.tar.gz "$DOWNLOAD_URL"

echo "Extracting Helm..."
tar -xzf helm.tar.gz

# Determine extracted folder (darwin-arm64 or darwin-amd64)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "darwin-*")

BASE_DIR="$HOME/Clitools"
TARGET_DIR="$BASE_DIR/helm"

# Ensure Clitools exists
mkdir -p "$BASE_DIR"

# Remove old installation if present
rm -rf "$TARGET_DIR"

# Move extracted folder to ~/Clitools/helm
mv "$EXTRACTED_DIR" "$TARGET_DIR"

# Add to PATH if not already present
if ! grep -q "Clitools/helm" ~/.zshrc; then
    echo "\n# Helm binary path" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> ~/.zshrc
fi

echo "Cleaning up..."
rm helm.tar.gz

echo "Refereshing the Terminal"
source ~/.zshrc
echo "Helm installation complete!"
echo " if it didnot execute thenRun the following command to activate Helm CLI:"
echo "source ~/.zshrc"
