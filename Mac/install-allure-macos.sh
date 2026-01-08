#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Fetches the latest Allure release from GitHub using GitHub API
# - Downloads the macOS-compatible Allure .tar.gz archive
# - Extracts Allure into $HOME/clitools/allure
# - Updates PATH in ~/.zshrc or ~/.bashrc (whichever exists)
# - Verifies the Allure installation
#
# Constraints:
# - No sudo usage
# - No Homebrew usage
# - Works on Intel & Apple Silicon macOS
###############################################################################

set -e

# ----------------------------- #
# Step 1: Define base variables #
# ----------------------------- #

# Base installation directory for CLI tools
INSTALL_BASE="$HOME/clitools"

# Final Allure installation directory
ALLURE_DIR="$INSTALL_BASE/allure"

# Temporary working directory
TMP_DIR="$(mktemp -d)"

# GitHub API endpoint for latest release
GITHUB_API_URL="https://api.github.com/repos/allure-framework/allure2/releases/latest"

# ----------------------------- #
# Step 2: Pre-flight checks     #
# ----------------------------- #

# Ensure required commands exist
for cmd in curl tar grep sed; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command '$cmd' not found."
    exit 1
  fi
done

# Create base directory if it does not exist
mkdir -p "$INSTALL_BASE"

# ----------------------------- #
# Step 3: Fetch latest version  #
# ----------------------------- #

echo "Fetching latest Allure release information..."

LATEST_VERSION=$(curl -fsSL "$GITHUB_API_URL" \
  | grep '"tag_name"' \
  | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "$LATEST_VERSION" ]]; then
  echo "ERROR: Unable to determine latest Allure version."
  exit 1
fi

echo "Latest Allure version detected: $LATEST_VERSION"

# ----------------------------- #
# Step 4: Build download URL    #
# ----------------------------- #

# Allure uses a generic .tgz package for macOS/Linux
ALLURE_TAR="allure-${LATEST_VERSION#v}.tgz"
DOWNLOAD_URL="https://github.com/allure-framework/allure2/releases/download/${LATEST_VERSION}/${ALLURE_TAR}"

echo "Download URL: $DOWNLOAD_URL"

# ----------------------------- #
# Step 5: Download Allure       #
# ----------------------------- #

echo "Downloading Allure..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/$ALLURE_TAR"

# ----------------------------- #
# Step 6: Extract Allure        #
# ----------------------------- #

echo "Extracting Allure..."

# Clean existing installation if present
rm -rf "$ALLURE_DIR"
mkdir -p "$ALLURE_DIR"

tar -xzf "$TMP_DIR/$ALLURE_TAR" -C "$ALLURE_DIR" --strip-components=1

# ----------------------------- #
# Step 7: Update PATH           #
# ----------------------------- #

ALLURE_BIN_PATH="$ALLURE_DIR/bin"

# Detect shell config file
if [[ -n "$ZSH_VERSION" || -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" || -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.profile"
fi

# Add PATH entry if not already present
if ! grep -q "$ALLURE_BIN_PATH" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# Allure CLI" >> "$SHELL_RC"
  echo "export PATH=\"$ALLURE_BIN_PATH:\$PATH\"" >> "$SHELL_RC"
  echo "PATH updated in $SHELL_RC"
else
  echo "PATH already configured in $SHELL_RC"
fi

# ----------------------------- #
# Step 8: Cleanup               #
# ----------------------------- #

rm -rf "$TMP_DIR"

# ----------------------------- #
# Step 9: Verification          #
# ----------------------------- #

export PATH="$ALLURE_BIN_PATH:$PATH"

echo "Verifying Allure installation..."
allure --version

ec
