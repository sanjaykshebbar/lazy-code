#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs NVM (Node Version Manager) on macOS
# - Uses the official NVM install script (no Homebrew)
# - Installs NVM in user space (~/.nvm)
# - Configures ~/.zshrc or ~/.bashrc automatically
# - Does not require sudo
###############################################################################

set -e

# ----------------------------- #
# Configuration                 #
# ----------------------------- #

NVM_DIR="$HOME/.nvm"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"

# ----------------------------- #
# Pre-flight checks             #
# ----------------------------- #

for cmd in curl; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: Required command '$cmd' not found."
    exit 1
  }
done

# ----------------------------- #
# Install NVM                   #
# ----------------------------- #

if [[ -d "$NVM_DIR" ]]; then
  echo "NVM already installed at $NVM_DIR"
else
  echo "Installing NVM..."
  curl -fsSL "$NVM_INSTALL_URL" | bash
fi

# ----------------------------- #
# Shell configuration           #
# ----------------------------- #

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.profile"
fi

# Ensure NVM initialization exists
if ! grep -q 'NVM_DIR="$HOME/.nvm"' "$RC"; then
  echo "" >> "$RC"
  echo "# NVM configuration" >> "$RC"
  echo 'export NVM_DIR="$HOME/.nvm"' >> "$RC"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$RC"
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$RC"
fi

# ----------------------------- #
# Load NVM for current session  #
# ----------------------------- #

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# ----------------------------- #
# Verification                  #
# ----------------------------- #

echo "Verification:"
nvm --version

echo "NVM installation completed successfully."
