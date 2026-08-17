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
# 2. Downloads the Apache JMeter binary from Apache mirrors.
# 3. Extracts the archive inside $HOME/CLI.
# 4. Renames the extracted version folder (apache-jmeter-x.x.x) to "jmeter".
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

# Apache JMeter download URL
JMETER_URL="https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz"

# Temporary file location
TMP_FILE="/tmp/apache-jmeter.tgz"

# Final installation folder
FINAL_DIR="$INSTALL_DIR/jmeter"

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
# Step 3 — Detect folder name inside archive
#############################################

echo "Detecting JMeter extracted folder..."

JMETER_FOLDER=$(tar -tzf "$TMP_FILE" | head -1 | cut -f1 -d"/")

#############################################
# Step 4 — Extract JMeter
#############################################

echo "Extracting JMeter..."

tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"

#############################################
# Step 5 — Remove old installation if exists
#############################################

if [ -d "$FINAL_DIR" ]; then
    echo "Existing JMeter installation detected. Removing old version..."
    rm -rf "$FINAL_DIR"
fi

#############################################
# Step 6 — Rename extracted folder
#############################################

echo "Renaming extracted folder to 'jmeter'..."

mv "$INSTALL_DIR/$JMETER_FOLDER" "$FINAL_DIR"

#############################################
# Step 7 — Add JMeter to PATH if not present
#############################################

SHELL_RC="$HOME/.zshrc"

if ! grep -q 'export PATH="$HOME/CLI/jmeter/bin:$PATH"' "$SHELL_RC"; then
    echo 'export PATH="$HOME/CLI/jmeter/bin:$PATH"' >> "$SHELL_RC"
    echo "PATH updated in $SHELL_RC"
fi

#############################################
# Step 8 — Load PATH for current session
#############################################

export PATH="$HOME/CLI/jmeter/bin:$PATH"

#############################################
# Step 9 — Verify Installation
#############################################

echo "Verifying installation..."

jmeter --version

#############################################
# Step 10 — Cleanup
#############################################

echo "Cleaning temporary files..."

rm -f "$TMP_FILE"

#############################################
# Completion Message
#############################################

echo ""
echo "Apache JMeter installation completed successfully."
echo "Installation Path: $FINAL_DIR"
echo "Run JMeter using: jmeter"
echo ""
