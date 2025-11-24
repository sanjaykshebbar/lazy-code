#!/bin/bash

set -e

echo "=========================================="
echo "   Terraform Installation (No Homebrew)  
echo "   macOS Intel + Apple Silicon
echo "=========================================="

# Terraform Version
TERRAFORM_VERSION="1.13.4"

# Detect Architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    PLATFORM="darwin_arm64"
    echo "Detected Apple Silicon (ARM64)"
else
    PLATFORM="darwin_amd64"
    echo "Detected Intel (x86_64)"
fi

# Directories
CLITOOLS="$HOME/Clitools"
TF_DIR="$CLITOOLS/terraform"
TMP_DIR="/tmp/terraform_install"

# Create dirs
mkdir -p "$TF_DIR"
mkdir -p "$TMP_DIR"

echo "Installing into: $TF_DIR"

cd "$TMP_DIR"

# ZIP name & download URL
TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_${PLATFORM}.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"

echo "Downloading Terraform from:"
echo "$DOWNLOAD_URL"

curl -LO "$DOWNLOAD_URL"

# Extract
unzip -o "$TERRAFORM_ZIP"

# Move terraform binary
mv terraform "$TF_DIR/terraform"
chmod +x "$TF_DIR/terraform"

# Cleanup
cd /
rm -rf "$TMP_DIR"

# Add PATH if missing
if ! grep -q 'export PATH="$HOME/Clitools/terraform:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/Clitools/terraform:$PATH"' >> ~/.zshrc
fi

echo "Reloading PATH…"
source ~/.zshrc || true

echo "=========================================="
echo "Terraform Installation Complete"
echo "Location: $TF_DIR/terraform"
echo "=========================================="

# Verify
"$TF_DIR/terraform" -version
