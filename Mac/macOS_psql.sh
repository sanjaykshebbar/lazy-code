#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Downloads official PostgreSQL macOS binaries
# - Installs only the psql CLI in user space
# - Configures PATH in ~/.zshrc or ~/.bashrc
# - Works without sudo and without Homebrew
###############################################################################

set -e

# ----------------------------- #
# Variables                     #
# ----------------------------- #

PG_VERSION="16.2"
BASE_DIR="$HOME/clitools/psql"
TMP_DIR="$(mktemp -d)"

ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  PG_ARCH="arm64"
else
  PG_ARCH="x86_64"
fi

PG_TAR="postgresql-${PG_VERSION}-osx-${PG_ARCH}-binaries.tar.gz"
PG_URL="https://ftp.postgresql.org/pub/binary/v${PG_VERSION}/osx/${PG_TAR}"

# ----------------------------- #
# Pre-checks                    #
# ----------------------------- #

for cmd in curl tar; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: $cmd not found"
    exit 1
  }
done

mkdir -p "$BASE_DIR"

# ----------------------------- #
# Download                      #
# ----------------------------- #

echo "Downloading PostgreSQL ${PG_VERSION} (${PG_ARCH})..."
cd "$TMP_DIR"
curl -fLO "$PG_URL"

# ----------------------------- #
# Extract                       #
# ----------------------------- #

echo "Extracting psql..."
tar -xzf "$PG_TAR"

# Copy only CLI-related files
cp -R postgresql/* "$BASE_DIR"

# ----------------------------- #
# PATH setup                    #
# ----------------------------- #

PSQL_BIN="$BASE_DIR/bin"

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.profile"
fi

if ! grep -q "$PSQL_BIN" "$RC"; then
  echo "" >> "$RC"
  echo "# PostgreSQL psql CLI" >> "$RC"
  echo "export PATH=\"$PSQL_BIN:\$PATH\"" >> "$RC"
fi

export PATH="$PSQL_BIN:$PATH"

# ----------------------------- #
# Cleanup                       #
# ----------------------------- #

rm -rf "$TMP_DIR"

# ----------------------------- #
# Verification                  #
# ----------------------------- #

psql --version
