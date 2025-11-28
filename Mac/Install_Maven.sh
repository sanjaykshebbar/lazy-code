#!/bin/sh

ARCH=$(uname -m)

# Detect architecture type
if [ "$ARCH" = "arm64" ]; then
    echo "Detected Mac Type: Apple Silicon (ARM64)"
    DOWNLOAD_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-aarch64.zip"
else
    echo "Detected Mac Type: Intel (x86_64)"
    DOWNLOAD_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-amd64.zip"
fi

echo "Downloading mvnd from: $DOWNLOAD_URL"
curl -L -o mvn.zip "$DOWNLOAD_URL"

echo "Unzipping..."
unzip -q mvn.zip

BASE_DIR="$HOME/Clitools"
TARGET_DIR="$BASE_DIR/mvn"

# Create folder if missing
mkdir -p "$BASE_DIR"

# Detect extracted folder
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "maven-mvnd-1.0.3*")

# Remove existing mvn folder to avoid conflicts
rm -rf "$TARGET_DIR"

# Move extracted directory into ~/Clitools/mvn
mv "$EXTRACTED_DIR" "$TARGET_DIR"

# Add PATH entries only if not already present
if ! grep -q "Clitools/mvn" ~/.zshrc; then
    echo "\n# Maven + mvnd path" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$TARGET_DIR/mvn/bin\"" >> ~/.zshrc   # mvn CLI
    echo "export PATH=\"\$PATH:$TARGET_DIR/bin\"" >> ~/.zshrc       # mvnd CLI
fi

echo "Cleaning up..."
rm mvn.zip

echo "Installation complete!"
echo "Run the following command to activate mvn and mvnd:"
echo "source ~/.zshrc"
