#!/bin/bash

###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# ----------------------
# This script installs Redis from source into a user-level directory
# ($HOME/Clitools/redis) on macOS.
#
# Key features:
# - Works on both Intel (x86_64) and Apple Silicon (arm64)
# - Does NOT use Homebrew
# - Does NOT require sudo/root access
# - Compiles Redis locally using system tools
# - Installs binaries, configuration, and data directories
# - Updates PATH safely via ~/.zshrc or ~/.bashrc
# - Verifies Redis installation
###############################################################################

set -e

# -----------------------------
# Variables
# -----------------------------
REDIS_VERSION="7.2.5"
INSTALL_BASE="$HOME/Clitools/redis"
SRC_DIR="$INSTALL_BASE/src"
BUILD_DIR="$INSTALL_BASE/build"
BIN_DIR="$INSTALL_BASE/bin"
CONF_DIR="$INSTALL_BASE/conf"
DATA_DIR="$INSTALL_BASE/data"

REDIS_TARBALL="redis-$REDIS_VERSION.tar.gz"
REDIS_URL="https://download.redis.io/releases/$REDIS_TARBALL"

# -----------------------------
# Detect shell profile
# -----------------------------
if [[ "$SHELL" == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.bashrc"
fi

# -----------------------------
# Pre-flight checks
# -----------------------------
echo "==> Checking required tools"

for cmd in curl tar make gcc; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found."
        exit 1
    fi
done

# -----------------------------
# Create directory structure
# -----------------------------
echo "==> Creating Redis directory structure"

mkdir -p "$SRC_DIR" "$BUILD_DIR" "$BIN_DIR" "$CONF_DIR" "$DATA_DIR"

# -----------------------------
# Download Redis source
# -----------------------------
echo "==> Downloading Redis $REDIS_VERSION source"

cd "$SRC_DIR"

if [[ ! -f "$REDIS_TARBALL" ]]; then
    curl -fL "$REDIS_URL" -o "$REDIS_TARBALL"
else
    echo "Source tarball already exists. Skipping download."
fi

# -----------------------------
# Extract source
# -----------------------------
echo "==> Extracting Redis source"

tar -xzf "$REDIS_TARBALL"

cd "redis-$REDIS_VERSION"

# -----------------------------
# Compile Redis
# -----------------------------
echo "==> Compiling Redis (no sudo, user-local build)"

make distclean >/dev/null 2>&1 || true
make BUILD_TLS=yes

# -----------------------------
# Install binaries manually
# -----------------------------
echo "==> Installing Redis binaries"

cp src/redis-server "$BIN_DIR/"
cp src/redis-cli "$BIN_DIR/"
cp src/redis-benchmark "$BIN_DIR/"
cp src/redis-check-aof "$BIN_DIR/"
cp src/redis-check-rdb "$BIN_DIR/"

# -----------------------------
# Install default config
# -----------------------------
echo "==> Installing default Redis configuration"

cp redis.conf "$CONF_DIR/redis.conf"

# Update config paths to user directory
sed -i '' \
    -e "s|^dir .*|dir $DATA_DIR|g" \
    -e "s|^bind .*|bind 127.0.0.1|g" \
    -e "s|^protected-mode .*|protected-mode yes|g" \
    "$CONF_DIR/redis.conf"

# -----------------------------
# Update PATH if needed
# -----------------------------
if ! grep -q "$BIN_DIR" "$PROFILE_FILE" 2>/dev/null; then
    echo "==> Updating PATH in $PROFILE_FILE"
    echo "" >> "$PROFILE_FILE"
    echo "# Redis CLI tools" >> "$PROFILE_FILE"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$PROFILE_FILE"
else
    echo "PATH already contains Redis bin directory"
fi

# -----------------------------
# Verify installation
# -----------------------------
echo "==> Verifying Redis installation"

"$BIN_DIR/redis-server" --version
"$BIN_DIR/redis-cli" --version

# -----------------------------
# Final instructions
# -----------------------------
echo ""
echo "===================================================="
echo "Redis installation completed successfully"
echo ""
echo "Install location : $INSTALL_BASE"
echo "Binary location  : $BIN_DIR"
echo "Config file      : $CONF_DIR/redis.conf"
echo "Data directory   : $DATA_DIR"
echo ""
echo "To start Redis:"
echo "redis-server $CONF_DIR/redis.conf"
echo ""
echo "Reload your shell or run:"
echo "source $PROFILE_FILE"
echo "===================================================="
