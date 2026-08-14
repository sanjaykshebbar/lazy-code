#!/bin/bash

set -euo pipefail

###############################################################################
# Apache JMeter - macOS Non-Sudo Installation
#
# Installs:
#   - Eclipse Temurin JDK 21
#   - Apache JMeter 5.6.3
#
# Installation location:
#   $HOME/CLI/
#
# No sudo required.
# No Homebrew required.
###############################################################################

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

JAVA_VERSION="21"
JMETER_VERSION="5.6.3"

INSTALL_ROOT="$HOME/CLI"
JAVA_ROOT="$INSTALL_ROOT/java"
JMETER_ROOT="$INSTALL_ROOT/jmeter"

TEMP_DIR="$HOME/.jmeter-install-temp"

SHELL_RC="$HOME/.zshrc"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# -----------------------------------------------------------------------------
# Check macOS
# -----------------------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This script is designed for macOS only."
fi

log "Detected macOS:"
sw_vers

# -----------------------------------------------------------------------------
# Check architecture
# -----------------------------------------------------------------------------

ARCH="$(uname -m)"

case "$ARCH" in

    arm64)
        ADOPTIUM_ARCH="aarch64"
        log "Architecture detected: Apple Silicon (arm64)"
        ;;

    x86_64)
        ADOPTIUM_ARCH="x64"
        log "Architecture detected: Intel (x86_64)"
        ;;

    *)
        error "Unsupported architecture: $ARCH"
        ;;

esac

# -----------------------------------------------------------------------------
# Check required commands
# -----------------------------------------------------------------------------

for command in curl tar unzip awk grep sed; do

    if ! command -v "$command" >/dev/null 2>&1; then
        error "Required command not found: $command"
    fi

done

success "Required system commands are available."

# -----------------------------------------------------------------------------
# Create directories
# -----------------------------------------------------------------------------

mkdir -p "$INSTALL_ROOT"
mkdir -p "$JAVA_ROOT"
mkdir -p "$JMETER_ROOT"
mkdir -p "$TEMP_DIR"

success "Installation directories created."

# -----------------------------------------------------------------------------
# Check existing Java
# -----------------------------------------------------------------------------

JAVA_HOME_VALUE=""

if command -v java >/dev/null 2>&1; then

    EXISTING_JAVA="$(java -version 2>&1 | head -n 1)"

    log "Existing Java detected:"
    echo "$EXISTING_JAVA"

    if /usr/libexec/java_home -v "$JAVA_VERSION" >/dev/null 2>&1; then

        JAVA_HOME_VALUE="$(/usr/libexec/java_home -v "$JAVA_VERSION")"

        success "Java $JAVA_VERSION already installed:"
        echo "$JAVA_HOME_VALUE"

    else

        warning "Java $JAVA_VERSION was not found."
        log "A user-local JDK will be installed."

    fi

else

    warning "Java is not currently installed."
    log "A user-local JDK will be installed."

fi

# -----------------------------------------------------------------------------
# Install Temurin JDK if required
# -----------------------------------------------------------------------------

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    log "Installing Eclipse Temurin JDK $JAVA_VERSION..."

    JAVA_ARCHIVE="$TEMP_DIR/temurin-jdk.tar.gz"

    JAVA_API_URL="https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/macos/${ADOPTIUM_ARCH}/jdk/hotspot/normal/eclipse"

    log "Downloading Java from Adoptium..."

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$JAVA_API_URL" \
        -o "$JAVA_ARCHIVE"

    success "Java archive downloaded."

    # Remove previous user-local Java installation if present
    rm -rf "$JAVA_ROOT"

    mkdir -p "$JAVA_ROOT"

    log "Extracting JDK..."

    tar -xzf "$JAVA_ARCHIVE" \
        -C "$JAVA_ROOT" \
        --strip-components=1

    # Validate Java
    if [[ ! -x "$JAVA_ROOT/bin/java" ]]; then
        error "Java installation failed. java executable was not found."
    fi

    JAVA_HOME_VALUE="$JAVA_ROOT"

    success "Temurin JDK installed under:"
    echo "$JAVA_HOME_VALUE"

fi

# -----------------------------------------------------------------------------
# Configure Java for current session
# -----------------------------------------------------------------------------

export JAVA_HOME="$JAVA_HOME_VALUE"
export PATH="$JAVA_HOME/bin:$PATH"

log "Java version:"
java -version

# -----------------------------------------------------------------------------
# Install Apache JMeter
# -----------------------------------------------------------------------------

log "Installing Apache JMeter $JMETER_VERSION..."

JMETER_ARCHIVE="$TEMP_DIR/apache-jmeter-${JMETER_VERSION}.tgz"

JMETER_URL="https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz"

log "Downloading JMeter..."

curl -fL \
    --retry 3 \
    --retry-delay 2 \
    "$JMETER_URL" \
    -o "$JMETER_ARCHIVE"

success "JMeter archive downloaded."

# -----------------------------------------------------------------------------
# Extract JMeter
# -----------------------------------------------------------------------------

rm -rf "$JMETER_ROOT"

mkdir -p "$JMETER_ROOT"

log "Extracting JMeter..."

tar -xzf "$JMETER_ARCHIVE" \
    -C "$TEMP_DIR"

EXTRACTED_JMETER="$TEMP_DIR/apache-jmeter-${JMETER_VERSION}"

if [[ ! -d "$EXTRACTED_JMETER" ]]; then
    error "JMeter extraction failed."
fi

mv "$EXTRACTED_JMETER" "$JMETER_ROOT"

success "JMeter installed under:"
echo "$JMETER_ROOT"

# -----------------------------------------------------------------------------
# Make JMeter executable
# -----------------------------------------------------------------------------

chmod +x "$JMETER_ROOT/bin/jmeter"
chmod +x "$JMETER_ROOT/bin/jmeter.sh"

# -----------------------------------------------------------------------------
# Create convenience symlinks
# -----------------------------------------------------------------------------

LOCAL_BIN="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN"

ln -sf "$JMETER_ROOT/bin/jmeter" "$LOCAL_BIN/jmeter"

success "JMeter command linked to:"
echo "$LOCAL_BIN/jmeter"

# -----------------------------------------------------------------------------
# Update ~/.zshrc
# -----------------------------------------------------------------------------

log "Configuring ~/.zshrc..."

touch "$SHELL_RC"

# Remove previous entries created by this script
sed -i '' '/# >>> JMeter User Installation >>>/,/# <<< JMeter User Installation <<</d' "$SHELL_RC"

cat >> "$SHELL_RC" <<EOF

# >>> JMeter User Installation >>>

export JAVA_HOME="$JAVA_HOME_VALUE"
export JMETER_HOME="$JMETER_ROOT"
export PATH="\$JAVA_HOME/bin:\$JMETER_HOME/bin:\$HOME/.local/bin:\$PATH"

# <<< JMeter User Installation <<<

EOF

success "~/.zshrc updated."

# -----------------------------------------------------------------------------
# Apply configuration to current shell
# -----------------------------------------------------------------------------

export JMETER_HOME="$JMETER_ROOT"
export PATH="$JAVA_HOME/bin:$JMETER_HOME/bin:$LOCAL_BIN:$PATH"

# -----------------------------------------------------------------------------
# Verify Java
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo " Java Verification"
echo "============================================================"

echo
echo "JAVA_HOME:"
echo "$JAVA_HOME"

echo
echo "Java:"
java -version

echo
echo "Javac:"
javac -version

# -----------------------------------------------------------------------------
# Verify JMeter
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo " JMeter Verification"
echo "============================================================"

echo
echo "JMETER_HOME:"
echo "$JMETER_HOME"

echo
echo "JMeter executable:"
command -v jmeter

echo
echo "JMeter version:"

jmeter --version

# -----------------------------------------------------------------------------
# Test JMeter CLI
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo " JMeter CLI Test"
echo "============================================================"

if "$JMETER_ROOT/bin/jmeter" -n -v >/dev/null 2>&1; then
    success "JMeter CLI is working."
else
    warning "JMeter CLI returned a non-zero status during validation."
fi

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

log "Cleaning temporary files..."

rm -rf "$TEMP_DIR"

success "Temporary files cleaned."

# -----------------------------------------------------------------------------
# Final output
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo " Installation Completed"
echo "============================================================"

echo
echo "Java:"
echo "  $JAVA_HOME"

echo
echo "JMeter:"
echo "  $JMETER_HOME"

echo
echo "JMeter command:"
echo "  $(command -v jmeter)"

echo
echo "Installed versions:"

echo
java -version

echo
jmeter --version

echo
echo "============================================================"
echo " IMPORTANT"
echo "============================================================"

echo
echo "Open a new Terminal session or run:"
echo
echo "    source ~/.zshrc"
echo
echo "Then verify:"
echo
echo "    java -version"
echo "    javac -version"
echo "    jmeter --version"
echo
echo "Launch JMeter GUI:"
echo
echo "    jmeter"
echo
echo "Run JMeter in CLI mode:"
echo
echo "    jmeter -n -t test.jmx -l results.jtl"
echo
echo "Generate HTML report:"
echo
echo "    jmeter -n -t test.jmx -l results.jtl -e -o report"
echo
echo "Installation location:"
echo
echo "    $INSTALL_ROOT"
echo
echo "No sudo was required."
echo
