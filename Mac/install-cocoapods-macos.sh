#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Builds OpenSSL, libyaml, and Ruby 3.x in user space
# - Forces RubyGems to use only user-defined directories
# - Installs CocoaPods without sudo and without Homebrew
# - Prevents writes to ~/.local or system paths
###############################################################################

set -e

# ----------------------------- #
# Versions                      #
# ----------------------------- #

RUBY_VERSION="3.3.0"
OPENSSL_VERSION="3.2.1"
LIBYAML_VERSION="0.2.5"

# ----------------------------- #
# Directories                   #
# ----------------------------- #

BASE="$HOME/CLI/cocoapods"
SRC="$BASE/src"

OPENSSL_DIR="$BASE/openssl"
LIBYAML_DIR="$BASE/libyaml"
RUBY_DIR="$BASE/ruby"

GEM_HOME="$BASE/gems"
GEM_PATH="$GEM_HOME"

XDG_DATA_HOME="$BASE/xdg-data"
XDG_CACHE_HOME="$BASE/xdg-cache"
XDG_CONFIG_HOME="$BASE/xdg-config"

mkdir -p "$SRC" "$GEM_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

# ----------------------------- #
# Export environment            #
# ----------------------------- #

export GEM_HOME GEM_PATH
export XDG_DATA_HOME XDG_CACHE_HOME XDG_CONFIG_HOME
export PATH="$RUBY_DIR/bin:$GEM_HOME/bin:$PATH"

# ----------------------------- #
# Toolchain check               #
# ----------------------------- #

for cmd in curl make clang tar; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: $cmd missing. Install Xcode Command Line Tools."
    exit 1
  }
done

# ----------------------------- #
# Build OpenSSL                 #
# ----------------------------- #

cd "$SRC"
if [[ ! -d "$OPENSSL_DIR" ]]; then
  curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
  tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
  cd "openssl-$OPENSSL_VERSION"

  ./Configure darwin64-$(uname -m)-cc \
    --prefix="$OPENSSL_DIR" \
    no-shared

  make -j"$(sysctl -n hw.ncpu)"
  make install_sw
fi

# ----------------------------- #
# Build libyaml                 #
# ----------------------------- #

cd "$SRC"
if [[ ! -d "$LIBYAML_DIR" ]]; then
  curl -LO "https://pyyaml.org/download/libyaml/yaml-$LIBYAML_VERSION.tar.gz"
  tar -xzf "yaml-$LIBYAML_VERSION.tar.gz"
  cd "yaml-$LIBYAML_VERSION"

  ./configure --prefix="$LIBYAML_DIR"
  make -j"$(sysctl -n hw.ncpu)"
  make install
fi

# ----------------------------- #
# Build Ruby                    #
# ----------------------------- #

cd "$SRC"
if [[ ! -d "$RUBY_DIR" ]]; then
  curl -LO "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-$RUBY_VERSION.tar.gz"
  tar -xzf "ruby-$RUBY_VERSION.tar.gz"
  cd "ruby-$RUBY_VERSION"

  ./configure \
    --prefix="$RUBY_DIR" \
    --with-openssl-dir="$OPENSSL_DIR" \
    --with-libyaml-dir="$LIBYAML_DIR"

  make -j"$(sysctl -n hw.ncpu)"
  make install
fi

# ----------------------------- #
# RubyGems hard isolation       #
# ----------------------------- #

echo "gem: --no-document" > "$BASE/gemrc"
export GEMRC="$BASE/gemrc"

# ----------------------------- #
# Install CocoaPods             #
# ----------------------------- #

echo "Installing CocoaPods..."
gem install cocoapods

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

if ! grep -q "$BASE/gems/bin" "$RC"; then
  echo "" >> "$RC"
  echo "# CocoaPods (user space)" >> "$RC"
  echo "export GEM_HOME=\"$GEM_HOME\"" >> "$RC"
  echo "export GEM_PATH=\"$GEM_PATH\"" >> "$RC"
  echo "export PATH=\"$RUBY_DIR/bin:$GEM_HOME/bin:\$PATH\"" >> "$RC"
fi

# ----------------------------- #
# Verification                  #
# ----------------------------- #

ruby --version
pod --version
