#!/bin/sh

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    DOWNLOAD_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-aarch64.zip"
else
    DOWNLOAD_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-amd64.zip"
fi

echo "Downloading mvnd from: $DOWNLOAD_URL"
curl -L -o mvnd.zip "$DOWNLOAD_URL"

echo "Unzipping..."
unzip -q mvnd.zip

# Set directory paths
BASE_DIR="$HOME/Clitools"
MAVEN_DIR="$BASE_DIR/mvnd"

# Create required directories
mkdir -p "$MAVEN_DIR"

# Move the extracted folder
mv maven-mvnd-1.0.3* "$MAVEN_DIR"

# Update PATH automatically
if ! grep -q 'Clitools/mvnd/bin' ~/.zshrc; then
    echo "\n# Maven mvnd path" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$MAVEN_DIR/bin\"" >> ~/.zshrc
fi

echo "Cleaning up..."
rm mvnd.zip

echo "Installation complete. Restart your terminal or run: source ~/.zshrc"
