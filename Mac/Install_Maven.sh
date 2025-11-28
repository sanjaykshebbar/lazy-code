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

# Define install paths
BASE_DIR="$HOME/Clitools"
MAVEN_DIR="$BASE_DIR/mvnd"

# Create required directories
mkdir -p "$MAVEN_DIR"

# Move extracted folder
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "maven-mvnd-1.0.3*")
mv "$EXTRACTED_DIR" "$MAVEN_DIR"

# Add the mvn and mvnd binaries to PATH
if ! grep -q "Clitools/mvnd" ~/.zshrc; then
    echo "\n# mvnd + maven path" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$MAVEN_DIR/maven-mvnd-1.0.3-darwin-amd64/mvn/bin\"" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$MAVEN_DIR/maven-mvnd-1.0.3-darwin-amd64/bin\"" >> ~/.zshrc
fi

echo "Cleaning up..."
rm mvnd.zip

echo "Installation complete!"
echo "Run: source ~/.zshrc"
