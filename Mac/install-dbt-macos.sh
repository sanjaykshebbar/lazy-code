#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Installs dbt (dbt-core) on macOS without sudo and without Homebrew
# - Creates a Python virtual environment in user space
# - Installs dbt-core (and dbt adapters can be added later)
# - Ensures dbt command works in the terminal
# - Works on both Intel and Apple Silicon macOS
###############################################################################

set -e

# ----------------------------- #
# Configuration                 #
# ----------------------------- #

INSTALL_DIR="$HOME/cli/dbt"
VENV_DIR="$INSTALL_DIR/venv"
BIN_DIR="$VENV_DIR/bin"

# ----------------------------- #
# Pre-flight checks             #
# ----------------------------- #

# Ensure Python 3 exists
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
else
  echo "ERROR: python3 not found. Install Python 3 first."
  exit 1
fi

# Ensure venv module exists
if ! "$PYTHON_BIN" -m venv --help >/dev/null 2>&1; then
  echo "ERROR: Python venv module not available."
  exit 1
fi

# ----------------------------- #
# Directory setup               #
# ----------------------------- #

mkdir -p "$INSTALL_DIR"

# ----------------------------- #
# Create virtual environment    #
# ----------------------------- #

if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating Python virtual environment..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
else
  echo "Virtual environment already exists. Skipping creation."
fi

# ----------------------------- #
# Activate virtual environment  #
# ----------------------------- #

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# ----------------------------- #
# Upgrade pip                   #
# ----------------------------- #

pip install --upgrade pip setuptools wheel

# ----------------------------- #
# Install dbt                   #
# ----------------------------- #

echo "Installing dbt-core..."
pip install dbt-core

# ----------------------------- #
# Shell PATH persist            #
# ----------------------------- #

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.profile"
fi

if ! grep -q "$BIN_DIR" "$RC"; then
  echo "" >> "$RC"
  echo "# dbt CLI (user-space)" >> "$RC"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$RC"
fi

# ----------------------------- #
# Verification                  #
# ----------------------------- #

echo "Verification:"
dbt --version

echo "dbt installation completed successfully."
