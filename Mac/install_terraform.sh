#!/bin/bash

set -e

echo "=========================================="
echo "   Terraform Installation (No Homebrew)"
echo "   macOS Intel + Apple Silicon"
echo "=========================================="

# Detect Architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    PLATFORM="darwin_arm64"
    echo "Detected Apple Silicon (ARM64)"
else
    PLATFORM="darwin_amd64"
    echo "Detected Intel (x86_64)"
fi

echo "[1/6] Fetching latest Terraform version..."

# Fetch latest version from HashiCorp API
TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)

if [[ -z "$TERRAFORM_VERSION" ]]; then
    echo "ERROR: Unable to fetch latest Terraform version!"
    exit 1
fi

echo "Latest Terraform Version: $TERRAFORM_VERSION"

# Paths
CLITOOLS="$HOME/Clitools"
TF_DIR="$CLITOOLS/terraform"
TMP_DIR="/tmp/terraform_install"

# Create dirs
mkdir -p "$TF_DIR"
mkdir -p "$TMP_DIR"

cd "$TMP_DIR"

echo "[2/6] Downloading Terraform..."

# ZIP name & URL
TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_${PLATFORM}.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"

echo "Downloading from:"
echo "$DOWNLOAD_URL"

curl -LO "$DOWNLOAD_URL"

echo "[3/6] Extracting Terraform..."
unzip -o "$TERRAFORM_ZIP"

echo "[4/6] Installing..."
mv terraform "$TF_DIR/terraform"
chmod +x "$TF_DIR/terraform"

cd /
rm -rf "$TMP_DIR"

echo "[5/6] Updating PATH..."
if ! grep -q 'export PATH="$HOME/Clitools/terraform:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/Clitools/terraform:$PATH"' >> ~/.zshrc
fi

source ~/.zshrc || true

echo "=========================================="
echo "Terraform Installation Complete!"
echo "Installed Version: $($TF_DIR/terraform -version)"
echo "Location: $TF_DIR/terraform"
echo "=========================================="
