#!/bin/bash

set -e

echo "=========================================="
echo "   FVM Installation (No Homebrew) - macOS"
echo "=========================================="

# Create directory structure
mkdir -p $HOME/Clitools
mkdir -p $HOME/Clitools/fvm
mkdir -p $HOME/Clitools/flutter_versions

cd $HOME/Clitools

echo "[1/7] Detecting CPU architecture..."
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    echo "Detected Apple Silicon (ARM64)"
    SDK_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-macos-arm64-release.zip"
else
    echo "Detected Intel macOS (x86_64)"
    SDK_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-macos-x64-release.zip"
fi

echo "[2/7] Downloading Dart SDK..."
curl -LO $SDK_URL

ZIP_FILE=$(basename $SDK_URL)

echo "[3/7] Extracting Dart SDK..."
unzip -q $ZIP_FILE
rm $ZIP_FILE

# Rename the folder properly
mv dart-sdk* dart-sdk

# Add Dart to PATH
echo "[4/7] Updating PATH for Dart..."
SHELL_RC="$HOME/.zshrc"
echo 'export PATH="$HOME/Clitools/dart-sdk/bin:$PATH"' >> $SHELL_RC
source $SHELL_RC

# Install FVM
echo "[5/7] Installing FVM..."
$HOME/Clitools/dart-sdk/bin/dart pub global activate fvm

# Move FVM binary to Clitools
echo "[6/7] Moving FVM binary into Clitools..."
cp $HOME/.pub-cache/bin/fvm $HOME/Clitools/fvm/
chmod +x $HOME/Clitools/fvm/fvm

# Add FVM to PATH
echo 'export PATH="$HOME/Clitools/fvm:$PATH"' >> $SHELL_RC
source $SHELL_RC

# Configure FVM cache directory
echo "[7/7] Configuring FVM cache path..."
$HOME/Clitools/fvm/fvm config --cache-path $HOME/Clitools/flutter_versions

echo "=========================================="
echo "   Installation Complete!"
echo "   Run 'fvm --version' to verify."
echo "=========================================="
