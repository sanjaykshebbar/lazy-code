#!/bin/zsh

####################################################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# This script installs FVM (Flutter Version Management) on macOS systems
# without requiring sudo/admin access.
#
# Features:
# 1. Supports both Intel and Apple Silicon (M1/M2/M3) Macs
# 2. Installs FVM inside:
#       $HOME/cli/fvm
# 3. Automatically detects the logged-in standard user
# 4. Ensures the standard user owns the ~/cli directory
# 5. Automatically updates ~/.zshrc
# 6. Reloads shell configuration automatically
# 7. Validates FVM installation
# 8. Works even when executed using sudo/admin account
#
# Use Case:
# Useful for:
# - Intune deployments
# - Jamf deployments
# - Admin-triggered installations
# - Shared Mac environments
#
####################################################################################################

# Exit immediately if any command fails
set -e

########################################
# DETECT ACTUAL LOGGED-IN USER
########################################

echo "=================================================="
echo "Detecting logged-in user..."
echo "=================================================="

# Get currently logged-in console user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Validate detected user
if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    echo "ERROR: Unable to determine logged-in standard user."
    exit 1
fi

echo "Detected standard user: $CURRENT_USER"

########################################
# USER HOME DIRECTORY
########################################

USER_HOME=$(dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | awk '{print $2}')

if [[ ! -d "$USER_HOME" ]]; then
    echo "ERROR: Home directory not found for user: $CURRENT_USER"
    exit 1
fi

echo "User Home Directory: $USER_HOME"

########################################
# VARIABLES
########################################

INSTALL_DIR="$USER_HOME/cli/fvm"
CLI_DIR="$USER_HOME/cli"
PUB_CACHE_DIR="$INSTALL_DIR/pub-cache"
ZSHRC_FILE="$USER_HOME/.zshrc"

########################################
# CREATE INSTALL DIRECTORY
########################################

echo "=================================================="
echo "Creating installation directories..."
echo "=================================================="

mkdir -p "$INSTALL_DIR"

########################################
# FIX OWNERSHIP
########################################

echo "=================================================="
echo "Setting ownership permissions..."
echo "=================================================="

# Ensure standard user owns the entire cli directory
chown -R "$CURRENT_USER":staff "$CLI_DIR"

echo "Ownership assigned to: $CURRENT_USER"

########################################
# DETECT MAC ARCHITECTURE
########################################

echo "=================================================="
echo "Detecting Mac architecture..."
echo "=================================================="

ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" ]]; then
    echo "Apple Silicon Mac detected (M1/M2/M3)"
elif [[ "$ARCH" == "x86_64" ]]; then
    echo "Intel Mac detected"
else
    echo "Unsupported architecture detected: $ARCH"
    exit 1
fi

########################################
# CHECK DART INSTALLATION
########################################

echo "=================================================="
echo "Checking Dart SDK..."
echo "=================================================="

# Run check as logged-in user
if sudo -u "$CURRENT_USER" command -v dart >/dev/null 2>&1; then
    echo "Dart SDK detected."
else
    echo "ERROR: Dart SDK not found for user: $CURRENT_USER"
    echo ""
    echo "Install Dart SDK before running this script."
    echo "https://dart.dev/get-dart"
    exit 1
fi

########################################
# CONFIGURE PUB CACHE
########################################

echo "=================================================="
echo "Configuring Pub Cache..."
echo "=================================================="

mkdir -p "$PUB_CACHE_DIR"

# Fix ownership again after folder creation
chown -R "$CURRENT_USER":staff "$CLI_DIR"

########################################
# INSTALL FVM
########################################

echo "=================================================="
echo "Installing FVM..."
echo "=================================================="

# Install FVM as the standard user
sudo -u "$CURRENT_USER" env PUB_CACHE="$PUB_CACHE_DIR" dart pub global activate fvm

########################################
# VERIFY FVM BINARY
########################################

FVM_BINARY="$PUB_CACHE_DIR/bin/fvm"

if [[ ! -f "$FVM_BINARY" ]]; then
    echo "ERROR: FVM installation failed."
    exit 1
fi

echo "FVM installation completed successfully."

########################################
# UPDATE .ZSHRC
########################################

echo "=================================================="
echo "Updating ~/.zshrc..."
echo "=================================================="

FVM_PATH='export PATH="$HOME/cli/fvm/pub-cache/bin:$PATH"'

# Create .zshrc if missing
sudo -u "$CURRENT_USER" touch "$ZSHRC_FILE"

# Prevent duplicate PATH entries
if grep -Fxq "$FVM_PATH" "$ZSHRC_FILE"; then
    echo "FVM PATH already exists in .zshrc"
else
    {
        echo ""
        echo "# FVM PATH"
        echo "$FVM_PATH"
    } >> "$ZSHRC_FILE"

    echo "FVM PATH added to .zshrc"
fi

########################################
# RELOAD ZSHRC
########################################

echo "=================================================="
echo "Reloading ~/.zshrc..."
echo "=================================================="

sudo -u "$CURRENT_USER" zsh -c "source '$ZSHRC_FILE'"

########################################
# VALIDATE INSTALLATION
########################################

echo "=================================================="
echo "Validating FVM installation..."
echo "=================================================="

if sudo -u "$CURRENT_USER" env PATH="$PUB_CACHE_DIR/bin:$PATH" command -v fvm >/dev/null 2>&1; then
    echo ""
    echo "FVM installed successfully."
    echo ""

    sudo -u "$CURRENT_USER" env PATH="$PUB_CACHE_DIR/bin:$PATH" fvm --version
else
    echo "ERROR: FVM command not found."
    exit 1
fi

########################################
# FINAL OWNERSHIP VALIDATION
########################################

echo "=================================================="
echo "Final ownership validation..."
echo "=================================================="

chown -R "$CURRENT_USER":staff "$CLI_DIR"

echo "Verified ownership for:"
echo "$CLI_DIR"

########################################
# DISPLAY INSTALLATION DETAILS
########################################

echo ""
echo "=================================================="
echo "INSTALLATION DETAILS"
echo "=================================================="
echo "Logged-in User   : $CURRENT_USER"
echo "Install Directory: $INSTALL_DIR"
echo "CLI Directory    : $CLI_DIR"
echo "Pub Cache Path   : $PUB_CACHE_DIR"
echo "Shell Config     : $ZSHRC_FILE"
echo "=================================================="
echo ""

echo "Usage Examples:"
echo "fvm install stable"
echo "fvm use stable"
echo ""
