#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Builds OpenSSL in user space
# - Builds libyaml in user space
# - Builds Ruby 3.x linked against OpenSSL & libyaml
# - Installs CocoaPods using the local Ruby
# - Configures PATH correctly
# - No sudo, no Homebrew, works on Intel & Apple Silicon macOS
###############################################################################

set -e

# ----------------------------- #
# Versions (pin explicitly)     #
# ----------------------------- #

RUBY_VERSION="3.3.0"
OPENSSL_VERSION="3.2.1"
LIBYAML_VERSION="0.2.5"

# ----------------------------- #
# Directories                   #
# ----------------------------- #

BASE_DIR="$HOME/CLI/cocoapods"
SRC_DIR="$BASE_DIR/src"
OPENSSL_PREFIX="$BASE_DIR/openssl"
LIBYAML_PREFIX="$BASE_DIR/libyaml"
RUBY_PREFIX="$BASE_DIR/ruby"

mkdir -p "$SRC_DIR"

# ----------------------------- #
# Toolchain check               #
# ----------------------------- #

for cmd in curl make clang tar; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: $cmd not found. Install Xcode Command Line Tools."
    exit 1
  }
done

# ----------------------------- #
# Build OpenSSL                 #
# ----------------------------- #

cd "$SRC_DIR"

if [[ ! -d "$OPENSSL_PREFIX" ]]; then
  echo "Building OpenSSL $OPENSSL_VERSION..."
  curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
  tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
  cd "openssl-$OPENSSL_VERSION"

  ./Configure darwin64-$(uname -m)-cc \
    --prefix="$OPENSSL_PREFIX" \
    no-shared

  make -j"$(sysctl -n hw.ncpu)"
  make install_sw
fi

# ----------------------------- #
# Build libyaml                 #
# ----------------------------- #

cd "$SRC_DIR"

if [[ ! -d "$LIBYAML_PREFIX" ]]; then
  echo "Building libyaml $LIBYAML_VERSION..."
  curl -LO "https://pyyaml.org/download/libyaml/yaml-$LIBYAML_VERSION.tar.gz"
  tar -xzf "yaml-$LIBYAML_VERSION.tar.gz"
  cd "yaml-$LIBYAML_VERSION"

  ./configure --prefix="$LIBYAML_PREFIX"
  make -j"$(sysctl -n hw.ncpu)"
  make install
fi

# ----------------------------- #
# Build Ruby                    #
# ----------------------------- #

cd "$SRC_DIR"

if [[ ! -d "$RUBY_PREFIX" ]]; then
  echo "Building Ruby $RUBY_VERSION..."
  curl -LO "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-$RUBY_VERSION.tar.gz"
  tar -xzf "ruby-$RUBY_VERSION.tar.gz"
  cd "ruby-$RUBY_VERSION"

  ./configure \
    --prefix="$RUBY_PREFIX" \
    --with-openssl-dir="$OPENSSL_PREFIX" \
    --with-libyaml-dir="$LIBYAML_PREFIX"

  make -j"$(sysctl -n hw.ncpu)"
  make install
fi

# ----------------------------- #
# PATH configuration            #
# ----------------------------- #

RUBY_BIN="$RUBY_PREFIX/bin"

if [[ -f "$HOME/.zshrc" ]]; then
  RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC="$HOME/.bashrc"
else
  RC="$HOME/.profile"
fi

if ! grep -q "$RUBY_BIN" "$RC"; then
  echo "" >> "$RC"
  echo "# Ruby & CocoaPods (user space)" >> "$RC"
  echo "export PATH=\"$RUBY_BIN:\$PATH\"" >> "$RC"
fi

export PATH="$RUBY_BIN:$PATH"

# ----------------------------- #
# Install CocoaPods             #
# ----------------------------- #

echo "Installing CocoaPods..."
gem update --system --no-document
gem install cocoapods --no-document

# ----------------------------- #
# Verification                  #
# ----------------------------- #

echo "Ruby:"
ruby --version

echo "OpenSSL:"
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_VERSION'

echo "YAML:"
ruby -ryaml -e 'puts YAML::VERSION'

echo "CocoaPods:"
pod --version
