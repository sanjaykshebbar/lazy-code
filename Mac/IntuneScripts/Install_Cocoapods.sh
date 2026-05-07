#!/usr/bin/env bash
###############################################################################
# Author  : Sanjay KS
# Email   : sanjaykshebbar@gmail.com
# GitHub  : https://github.com/sanjaykshebbar/Automation
#
# What does this code do:
# - Detects the currently logged-in macOS user during Intune execution
# - Fixes ownership of ~/.local from root to logged-in user
# - Builds OpenSSL, libyaml, and Ruby 3.x completely in user space
# - Installs CocoaPods without sudo and without Homebrew
# - Prevents system Ruby usage
# - Prevents writes to system gem locations
# - Ensures all Ruby dependencies work from ~/.local
# - Persists PATH and GEM environment variables for future shells
###############################################################################

set -euo pipefail

###############################################################################
# LOGGING
###############################################################################

LOG_DIR="/Library/Logs/IntuneScripts"
LOG_FILE="$LOG_DIR/ruby-cocoapods-install.log"

mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================================="
echo "Ruby + CocoaPods User Space Installation Started"
echo "=================================================="

###############################################################################
# DETECT LOGGED-IN USER
###############################################################################

CURRENT_USER=$(stat -f "%Su" /dev/console)

if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    echo "ERROR: Unable to detect logged-in user."
    exit 1
fi

USER_HOME=$(dscl . -read /Users/"$CURRENT_USER" NFSHomeDirectory | awk '{print $2}')

if [[ ! -d "$USER_HOME" ]]; then
    echo "ERROR: Home directory not found for user: $CURRENT_USER"
    exit 1
fi

echo "Logged-in user detected: $CURRENT_USER"
echo "Home directory: $USER_HOME"

###############################################################################
# VERSION CONFIGURATION
###############################################################################

RUBY_VERSION="3.3.0"
OPENSSL_VERSION="3.2.1"
LIBYAML_VERSION="0.2.5"

###############################################################################
# USER-SPACE INSTALLATION PATHS
###############################################################################

BASE="$USER_HOME/.local"

SRC="$BASE/src"

OPENSSL_DIR="$BASE/openssl"
LIBYAML_DIR="$BASE/libyaml"
RUBY_DIR="$BASE/ruby"

GEM_HOME="$BASE/gems"
GEM_PATH="$GEM_HOME"

XDG_DATA_HOME="$BASE/xdg-data"
XDG_CACHE_HOME="$BASE/xdg-cache"
XDG_CONFIG_HOME="$BASE/xdg-config"

###############################################################################
# CREATE DIRECTORIES
###############################################################################

mkdir -p \
    "$SRC" \
    "$GEM_HOME" \
    "$XDG_DATA_HOME" \
    "$XDG_CACHE_HOME" \
    "$XDG_CONFIG_HOME"

###############################################################################
# FIX OWNERSHIP
#
# Intune scripts typically execute as root.
# This ensures ~/.local belongs to the actual user.
###############################################################################

echo "Fixing ownership for $BASE"

chown -R "$CURRENT_USER":staff "$BASE"

###############################################################################
# EXPORT ENVIRONMENT
###############################################################################

export GEM_HOME
export GEM_PATH

export XDG_DATA_HOME
export XDG_CACHE_HOME
export XDG_CONFIG_HOME

export PATH="$RUBY_DIR/bin:$GEM_HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin"

###############################################################################
# TOOLCHAIN VALIDATION
###############################################################################

echo "Validating required build tools..."

for cmd in curl make clang tar; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Missing required command: $cmd"
        echo "Install Xcode Command Line Tools first."
        exit 1
    }
done

###############################################################################
# CPU THREAD COUNT
###############################################################################

CPU_COUNT=$(sysctl -n hw.ncpu)

###############################################################################
# BUILD OPENSSL
###############################################################################

if [[ ! -d "$OPENSSL_DIR" ]]; then

    echo "Building OpenSSL $OPENSSL_VERSION"

    cd "$SRC"

    rm -rf "openssl-$OPENSSL_VERSION"

    curl --retry 5 --retry-delay 5 -LO \
        "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"

    tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"

    cd "openssl-$OPENSSL_VERSION"

    ./Configure "darwin64-$(uname -m)-cc" \
        --prefix="$OPENSSL_DIR" \
        no-shared

    make -j"$CPU_COUNT"

    make install_sw

    echo "OpenSSL build completed"

else
    echo "OpenSSL already installed"
fi

###############################################################################
# BUILD LIBYAML
###############################################################################

if [[ ! -d "$LIBYAML_DIR" ]]; then

    echo "Building libyaml $LIBYAML_VERSION"

    cd "$SRC"

    rm -rf "yaml-$LIBYAML_VERSION"

    curl --retry 5 --retry-delay 5 -LO \
        "https://pyyaml.org/download/libyaml/yaml-$LIBYAML_VERSION.tar.gz"

    tar -xzf "yaml-$LIBYAML_VERSION.tar.gz"

    cd "yaml-$LIBYAML_VERSION"

    ./configure --prefix="$LIBYAML_DIR"

    make -j"$CPU_COUNT"

    make install

    echo "libyaml build completed"

else
    echo "libyaml already installed"
fi

###############################################################################
# BUILD RUBY
###############################################################################

if [[ ! -d "$RUBY_DIR" ]]; then

    echo "Building Ruby $RUBY_VERSION"

    cd "$SRC"

    rm -rf "ruby-$RUBY_VERSION"

    curl --retry 5 --retry-delay 5 -LO \
        "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-$RUBY_VERSION.tar.gz"

    tar -xzf "ruby-$RUBY_VERSION.tar.gz"

    cd "ruby-$RUBY_VERSION"

    export CPPFLAGS="-I$OPENSSL_DIR/include -I$LIBYAML_DIR/include"
    export LDFLAGS="-L$OPENSSL_DIR/lib -L$LIBYAML_DIR/lib"

    ./configure \
        --prefix="$RUBY_DIR" \
        --with-openssl-dir="$OPENSSL_DIR" \
        --with-libyaml-dir="$LIBYAML_DIR" \
        --disable-install-doc

    make -j"$CPU_COUNT"

    make install

    echo "Ruby build completed"

else
    echo "Ruby already installed"
fi

###############################################################################
# RUBYGEMS CONFIGURATION
###############################################################################

echo "Configuring RubyGems"

cat > "$BASE/gemrc" <<EOF
gem: --no-document
EOF

export GEMRC="$BASE/gemrc"

###############################################################################
# ENSURE USER OWNS ENTIRE .LOCAL
###############################################################################

chown -R "$CURRENT_USER":staff "$BASE"

###############################################################################
# INSTALL FFI
#
# Explicit ffi version prevents Apple Silicon issues
###############################################################################

echo "Installing ffi"

gem install ffi -v 1.17.3 --no-document

###############################################################################
# INSTALL COCOAPODS
###############################################################################

echo "Installing CocoaPods"

gem install cocoapods --no-document

###############################################################################
# SHELL PROFILE PERSISTENCE
###############################################################################

echo "Persisting PATH configuration"

PROFILE_FILES=(
    "$USER_HOME/.zprofile"
    "$USER_HOME/.zshrc"
    "$USER_HOME/.bash_profile"
    "$USER_HOME/.bashrc"
    "$USER_HOME/.profile"
)

for profile in "${PROFILE_FILES[@]}"; do

    touch "$profile"

    if ! grep -q "$RUBY_DIR/bin" "$profile"; then

        {
            echo ""
            echo "# Ruby + CocoaPods User Space Configuration"
            echo "export GEM_HOME=\"$GEM_HOME\""
            echo "export GEM_PATH=\"$GEM_PATH\""
            echo "export XDG_DATA_HOME=\"$XDG_DATA_HOME\""
            echo "export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
            echo "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
            echo "export PATH=\"$RUBY_DIR/bin:$GEM_HOME/bin:\$PATH\""
        } >> "$profile"
    fi

    chown "$CURRENT_USER":staff "$profile"

done

###############################################################################
# FINAL OWNERSHIP FIX
###############################################################################

echo "Applying final ownership correction"

chown -R "$CURRENT_USER":staff "$BASE"

###############################################################################
# VALIDATION
###############################################################################

echo ""
echo "=================================================="
echo "VALIDATION"
echo "=================================================="

echo "Ruby Version:"
ruby --version

echo ""
echo "Gem Version:"
gem --version

echo ""
echo "CocoaPods Version:"
pod --version

echo ""
echo "Gem Environment:"
gem env home

echo ""
echo "=================================================="
echo "INSTALLATION COMPLETED SUCCESSFULLY"
echo "=================================================="
