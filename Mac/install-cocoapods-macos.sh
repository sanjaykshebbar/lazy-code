#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Downloads and installs Ruby 3.x from source in user space
# - Installs CocoaPods using the locally installed Ruby
# - Configures PATH so pod command is available globally for the user
# - Works without sudo and without Homebrew on macOS
###############################################################################

set -e

# ----------------------------- #
# Step 1: Variables             #
# ----------------------------- #

BASE_DIR="$HOME/CLI/cocoapods"
RUBY_VERSION="3.3.0"
RUBY_PREFIX="$BASE_DIR/ruby"
TMP_DIR="$(mktemp -d)"

RUBY_TAR="ruby-$RUBY_VERSION.tar.gz"
RUBY_URL="https://cache.ruby-lang.org/pub/ruby/3.3/$RUBY_TAR"

# ----------------------------- #
# Step 2: Dependency checks     #
# ----------------------------- #

for cmd in curl tar make gcc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command '$cmd' not found. Install Xcode Command Line Tools."
    exit 1
  fi
done

# ----------------------------- #
# Step 3: Directory setup       #
# ----------------------------- #

mkdir -p "$BASE_DIR"

# ----------------------------- #
# Step 4: Download Ruby         #
# ----------------------------- #

echo "Downloading Ruby $RUBY_VERSION..."
cd "$TMP_DIR"
curl -fLO "$RUBY_URL"

# ----------------------------- #
# Step 5: Build Ruby            #
# ----------------------------- #

echo "Building Ruby..."
tar -xzf "$RUBY_TAR"
cd "ruby-$RUBY_VERSION"

./configure --prefix="$RUBY_PREFIX"
make -j"$(sysctl -n hw.ncpu)"
make install

# ----------------------------- #
# Step 6: Configure PATH        #
# ----------------------------- #

RUBY_BIN="$RUBY_PREFIX/bin"

if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.profile"
fi

if ! grep -q "$RUBY_BIN" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "# Ruby & CocoaPods (user-local)" >> "$SHELL_RC"
  echo "export PATH=\"$RUBY_BIN:\$PATH\"" >> "$SHELL_RC"
fi

export PATH="$RUBY_BIN:$PATH"

# ----------------------------- #
# Step 7: Install CocoaPods     #
# ----------------------------- #

echo "Installing CocoaPods..."
gem update --system
gem install cocoapods --no-document

# ----------------------------- #
# Step 8: Cleanup               #
# ----------------------------- #

rm -rf "$TMP_DIR"

# ----------------------------- #
# Step 9: Verification          #
# ----------------------------- #

echo "Ruby version:"
ruby --version

echo "CocoaPods version:"
pod --version

echo "CocoaPods installed successfully in user space."
