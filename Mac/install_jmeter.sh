#!/bin/bash

###################################################################################################
# Author  - Sanjay KS
# Email   - sanjaykshebbar@gmail.com
# GitHub  - https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# This script installs Apache JMeter on macOS inside the $HOME/CLI directory.
#
# Actions performed:
# 1. Creates CLI directory in user's home folder if it does not exist.
# 2. Downloads the latest stable Apache JMeter binary from Apache mirrors.
# 3. Extracts the archive inside $HOME/CLI.
# 4. Creates a symbolic link called "jmeter" pointing to the installed version.
# 5. Adds $HOME/CLI/jmeter/bin to PATH for easier command execution.
# 6. Verifies installation by printing the installed JMeter version.
#
# Apache JMeter:
# Open-source load testing tool developed by Apache Software Foundation
# used for performance testing, functional testing, and API testing.
###################################################################################################

set -e

#############################################
# Variables
#############################################

# Installation directory
INSTALL_DIR="$HOME/CLI"

# Apache JMeter download URL (latest stable)
JMETER_URL="https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz"

# Temporary download location
TMP_FILE="/tmp/apache-jmeter.tgz"

#############################################
# Step 1 — Create CLI directory
#############################################

echo "Creating CLI directory if it does not exist..."

mkdir -p "$INSTALL_DIR"

#############################################
# Step 2 — Download Apache JMeter
#############################################

echo "Downloading Apache JMeter..."

curl -L "$JMETER_URL" -o "$TMP_FILE"

#############################################
# Step 3 — Extract JMeter
#############################################

echo "Extracting JMeter to $INSTALL_DIR ..."

tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"

#############################################
# Step 4 — Detect extracted directory
#############################################

JMETER_FOLDER=$(tar -tzf "$TMP_FILE" | head -1 | cut -f1 -d"/")

#############################################
# Step 5 — Create symlink for easy access
#############################################

echo "Creating symbolic link..."

ln -sf "$INSTALL_DIR/$JMETER_FOLDER" "$INSTALL_DIR/jmeter"

#############################################
# Step 6 — Add to PATH if not already present
#############################################

SHELL_RC="$HOME/.zshrc"

if ! grep -q 'export PATH="$HOME/CLI/jmeter/bin:$PATH"' "$SHELL_RC"; then
    echo 'export PATH="$HOME/CLI/jmeter/bin:$PATH"' >> "$SHELL_RC"
    echo "PATH updated in $SHELL_RC"
fi

#############################################
# Step 7 — Load updated PATH
#############################################

export PATH="$HOME/CLI/jmeter/bin:$PATH"

#############################################
# Step 8 — Verify installation
#############################################

echo "Verifying installation..."

jmeter --version

#############################################
# Step 9 — Cleanup
#############################################

rm -f "$TMP_FILE"

echo ""
echo "Apache JMeter installation completed."
echo "Installation Path: $INSTALL_DIR/jmeter"
echo "Run using command: jmeter"
echo ""
