#!/bin/bash
set -e

# -------------------------------------------------
# NOTE:
# Xcode Command Line Tools MUST be installed
# before running this script.
#
# Install manually (one-time):
#   xcode-select --install
# -------------------------------------------------

# -------- CONFIG --------
GPG_VERSION="2.4.5"
PREFIX="$HOME/cli/gnupg"
SRC_DIR="$HOME/src/gnupg"
URL="https://mirrors.kernel.org/gnupg/gnupg/gnupg-${GPG_VERSION}.tar.bz2"
# ------------------------

echo "==> Installing GnuPG ${GPG_VERSION} (no Homebrew)"
echo "==> Install prefix: ${PREFIX}"

# 1. Prepare directories
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# 2. Download source
if [ ! -f "gnupg-${GPG_VERSION}.tar.bz2" ]; then
  echo "==> Downloading GnuPG source"
  curl -fLO "$URL"
else
  echo "==> Source archive already exists, skipping download"
fi

# 3. Extract
echo "==> Extracting source"
tar -xjf "gnupg-${GPG_VERSION}.tar.bz2"
cd "gnupg-${GPG_VERSION}"

# 4. Configure
echo "==> Configuring build"
./configure --prefix="$PREFIX"

# 5. Build
echo "==> Building"
make -j"$(sysctl -n hw.ncpu)"

# 6. Install
echo "==> Installing"
make install

# 7. Update PATH (zsh + bash)
if ! grep -q "$PREFIX/bin" "$HOME/.zshrc" 2>/dev/null; then
  echo "export PATH=\"$PREFIX/bin:\$PATH\"" >> "$HOME/.zshrc"
fi

if ! grep -q "$PREFIX/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$PREFIX/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

# 8. Reload PATH for current session
export PATH="$PREFIX/bin:$PATH"

# 9. Verify
echo "==> Verification"
which gpg
gpg --version

echo "==> GnuPG installation completed"
