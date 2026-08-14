#!/bin/bash

###############################################################################
# Apache JMeter + Java 21
# macOS User-Level Installation
#
# Requirements:
#   - macOS
#   - Standard user account
#   - Internet access
#
# Does NOT require:
#   - sudo
#   - Homebrew
#   - Administrator privileges
#
# Installation:
#   $HOME/CLI/java
#   $HOME/CLI/jmeter
#   $HOME/.local/bin/jmeter
#
###############################################################################

set -uo pipefail

###############################################################################
# Configuration
###############################################################################

JAVA_VERSION="21"
JMETER_VERSION="5.6.3"

INSTALL_ROOT="$HOME/CLI"
JAVA_ROOT="$INSTALL_ROOT/java"
JMETER_ROOT="$INSTALL_ROOT/jmeter"

LOCAL_BIN="$HOME/.local/bin"
TEMP_DIR="$HOME/.jmeter-install-temp"

SHELL_RC="$HOME/.zshrc"

###############################################################################
# Colors
###############################################################################

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

###############################################################################
# Logging
###############################################################################

info() {
    printf "%b[INFO]%b %s\n" "$BLUE" "$NC" "$1"
}

success() {
    printf "%b[OK]%b %s\n" "$GREEN" "$NC" "$1"
}

warning() {
    printf "%b[WARNING]%b %s\n" "$YELLOW" "$NC" "$1"
}

error() {
    printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1"
}

###############################################################################
# Exit Handler
###############################################################################

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

###############################################################################
# Error Handler
###############################################################################

die() {
    error "$1"
    exit 1
}

###############################################################################
# Banner
###############################################################################

printf "\n"
printf "%b============================================================%b\n" "$CYAN" "$NC"
printf "%b Apache JMeter macOS Installation%b\n" "$CYAN" "$NC"
printf "%b============================================================%b\n" "$CYAN" "$NC"
printf "\n"

###############################################################################
# Check OS
###############################################################################

if [[ "$(uname -s)" != "Darwin" ]]; then
    die "This script supports macOS only."
fi

info "Detected macOS:"
sw_vers

printf "\n"

###############################################################################
# Check macOS version
###############################################################################

MACOS_VERSION="$(sw_vers -productVersion)"

info "macOS version: $MACOS_VERSION"

###############################################################################
# Detect Architecture
###############################################################################

ARCH="$(uname -m)"

case "$ARCH" in

    arm64)
        ADOPTIUM_ARCH="aarch64"
        info "Architecture detected: Apple Silicon (arm64)"
        ;;

    x86_64)
        ADOPTIUM_ARCH="x64"
        info "Architecture detected: Intel (x86_64)"
        ;;

    *)
        die "Unsupported architecture: $ARCH"
        ;;

esac

###############################################################################
# Check User
###############################################################################

if [[ "$EUID" -eq 0 ]]; then
    die "Do not run this script as root or with sudo."
fi

success "Running as standard user: $USER"

###############################################################################
# Check Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    curl
    tar
    mkdir
    rm
    mv
    ln
    chmod
    sed
    grep
    awk
)

info "Checking required system commands..."

for command in "${REQUIRED_COMMANDS[@]}"; do

    if ! command -v "$command" >/dev/null 2>&1; then
        die "Required command not found: $command"
    fi

done

success "Required system commands are available."

###############################################################################
# Create Directories
###############################################################################

info "Creating user-level installation directories..."

mkdir -p "$INSTALL_ROOT"
mkdir -p "$LOCAL_BIN"
mkdir -p "$TEMP_DIR"

success "Installation directories created."

###############################################################################
# JAVA DETECTION
###############################################################################

JAVA_HOME_VALUE=""

printf "\n"
info "Checking for Java $JAVA_VERSION..."

###############################################################################
# Check current JAVA_HOME
###############################################################################

if [[ -n "${JAVA_HOME:-}" ]]; then

    if [[ -x "$JAVA_HOME/bin/java" ]]; then

        CURRENT_JAVA_VERSION="$(
            "$JAVA_HOME/bin/java" -version 2>&1 |
            awk -F '"' '/version/ {print $2; exit}'
        )"

        if [[ "$CURRENT_JAVA_VERSION" == 21* ]]; then

            JAVA_HOME_VALUE="$JAVA_HOME"

            success "Java 21 already configured:"
            echo "       $JAVA_HOME_VALUE"

        fi

    fi

fi

###############################################################################
# Check macOS Java installation
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    JAVA_HOME_DETECTED=""

    if JAVA_HOME_DETECTED="$(
        /usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null
    )"; then

        if [[ -n "$JAVA_HOME_DETECTED" ]] &&
           [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

            JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

            success "Java $JAVA_VERSION found:"
            echo "       $JAVA_HOME_VALUE"

        fi

    fi

fi

###############################################################################
# Check java command
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    if command -v java >/dev/null 2>&1; then

        SYSTEM_JAVA="$(command -v java)"

        JAVA_VERSION_DETECTED="$(
            "$SYSTEM_JAVA" -version 2>&1 |
            awk -F '"' '/version/ {print $2; exit}'
        )"

        info "Existing Java detected: ${JAVA_VERSION_DETECTED:-unknown}"

        if [[ "$JAVA_VERSION_DETECTED" == 21* ]]; then

            JAVA_HOME_DETECTED="$(
                /usr/libexec/java_home 2>/dev/null || true
            )"

            if [[ -n "$JAVA_HOME_DETECTED" ]] &&
               [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

                JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

                success "Existing Java 21 will be used."

            fi

        fi

    fi

fi

###############################################################################
# Install Java if required
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    printf "\n"
    info "Java $JAVA_VERSION is not available."
    info "Installing Eclipse Temurin JDK $JAVA_VERSION locally..."
    printf "\n"

    JAVA_ARCHIVE="$TEMP_DIR/temurin-jdk.tar.gz"

    JAVA_API_URL="https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/macos/${ADOPTIUM_ARCH}/jdk/hotspot/normal/eclipse"

    info "Downloading Temurin JDK..."
    info "Architecture: $ADOPTIUM_ARCH"

    if ! curl -fL \
        --retry 3 \
        --retry-delay 2 \
        --connect-timeout 20 \
        --max-time 600 \
        "$JAVA_API_URL" \
        -o "$JAVA_ARCHIVE"; then

        die "Failed to download Temurin JDK."
    fi

    success "JDK download completed."

    ###########################################################################
    # Validate archive
    ###########################################################################

    if [[ ! -s "$JAVA_ARCHIVE" ]]; then
        die "Downloaded Java archive is empty."
    fi

    ###########################################################################
    # Remove old local Java installation
    ###########################################################################

    if [[ -d "$JAVA_ROOT" ]]; then
        warning "Existing local Java installation found."
        info "Replacing: $JAVA_ROOT"

        rm -rf "$JAVA_ROOT"
    fi

    mkdir -p "$JAVA_ROOT"

    ###########################################################################
    # Extract Java
    ###########################################################################

    info "Extracting JDK..."

    if ! tar -xzf "$JAVA_ARCHIVE" \
        -C "$JAVA_ROOT" \
        --strip-components=1; then

        die "Failed to extract JDK archive."
    fi

    ###########################################################################
    # Validate Java
    ###########################################################################

    if [[ ! -x "$JAVA_ROOT/bin/java" ]]; then
        die "Java installation failed. java executable not found."
    fi

    if [[ ! -x "$JAVA_ROOT/bin/javac" ]]; then
        warning "javac executable was not found."
    fi

    JAVA_HOME_VALUE="$JAVA_ROOT"

    success "Temurin JDK installed:"
    echo "       $JAVA_HOME_VALUE"

fi

###############################################################################
# Configure Java Current Session
###############################################################################

export JAVA_HOME="$JAVA_HOME_VALUE"
export PATH="$JAVA_HOME/bin:$PATH"

###############################################################################
# Validate Java
###############################################################################

printf "\n"
info "Validating Java..."

JAVA_VERSION_OUTPUT="$(
    "$JAVA_HOME/bin/java" -version 2>&1
)"

echo "$JAVA_VERSION_OUTPUT"

JAVA_MAJOR_VERSION="$(
    "$JAVA_HOME/bin/java" -version 2>&1 |
    awk -F '"' '/version/ {print $2; exit}' |
    awk -F. '{print $1}'
)"

if [[ "$JAVA_MAJOR_VERSION" != "21" ]]; then
    die "Expected Java 21 but detected: ${JAVA_MAJOR_VERSION:-unknown}"
fi

success "Java 21 is working."

###############################################################################
# JMETER INSTALLATION
###############################################################################

printf "\n"
info "Installing Apache JMeter $JMETER_VERSION..."

JMETER_ARCHIVE="$TEMP_DIR/apache-jmeter-${JMETER_VERSION}.tgz"

JMETER_URL="https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz"

###############################################################################
# Download JMeter
###############################################################################

info "Downloading Apache JMeter..."

if ! curl -fL \
    --retry 3 \
    --retry-delay 2 \
    --connect-timeout 20 \
    --max-time 600 \
    "$JMETER_URL" \
    -o "$JMETER_ARCHIVE"; then

    die "Failed to download Apache JMeter."
fi

success "JMeter download completed."

###############################################################################
# Validate JMeter archive
###############################################################################

if [[ ! -s "$JMETER_ARCHIVE" ]]; then
    die "JMeter archive is empty."
fi

###############################################################################
# Extract JMeter
###############################################################################

EXTRACT_DIR="$TEMP_DIR/apache-jmeter-${JMETER_VERSION}"

rm -rf "$EXTRACT_DIR"

info "Extracting JMeter..."

if ! tar -xzf "$JMETER_ARCHIVE" \
    -C "$TEMP_DIR"; then

    die "Failed to extract JMeter archive."
fi

if [[ ! -d "$EXTRACT_DIR" ]]; then
    die "JMeter extraction directory was not found."
fi

###############################################################################
# Replace existing installation
###############################################################################

if [[ -d "$JMETER_ROOT" ]]; then

    warning "Existing JMeter installation found:"
    echo "       $JMETER_ROOT"

    info "Replacing existing installation..."

    rm -rf "$JMETER_ROOT"

fi

###############################################################################
# Move JMeter
###############################################################################

mv "$EXTRACT_DIR" "$JMETER_ROOT"

success "JMeter installed:"
echo "       $JMETER_ROOT"

###############################################################################
# Permissions
###############################################################################

chmod +x "$JMETER_ROOT/bin/jmeter"
chmod +x "$JMETER_ROOT/bin/jmeter.sh"

###############################################################################
# Create JMeter Symlink
###############################################################################

info "Creating JMeter command..."

ln -sf \
    "$JMETER_ROOT/bin/jmeter" \
    "$LOCAL_BIN/jmeter"

success "JMeter command created:"
echo "       $LOCAL_BIN/jmeter"

###############################################################################
# Configure Shell
###############################################################################

printf "\n"
info "Configuring shell environment..."

touch "$SHELL_RC"

###############################################################################
# Remove previous configuration
###############################################################################

TEMP_RC="$TEMP_DIR/zshrc.new"

awk '
/# >>> JMeter User Installation >>>/ {
    skip=1
    next
}

/# <<< JMeter User Installation <<</ {
    skip=0
    next
}

!skip {
    print
}
' "$SHELL_RC" > "$TEMP_RC"

mv "$TEMP_RC" "$SHELL_RC"

###############################################################################
# Add configuration
###############################################################################

cat >> "$SHELL_RC" <<EOF

# >>> JMeter User Installation >>>

export JAVA_HOME="$JAVA_HOME_VALUE"
export JMETER_HOME="$JMETER_ROOT"
export PATH="\$JAVA_HOME/bin:\$JMETER_HOME/bin:\$HOME/.local/bin:\$PATH"

# <<< JMeter User Installation <<

EOF

success "Shell configuration updated."

###############################################################################
# Configure Current Shell
###############################################################################

export JAVA_HOME="$JAVA_HOME_VALUE"
export JMETER_HOME="$JMETER_ROOT"
export PATH="$JAVA_HOME/bin:$JMETER_HOME/bin:$LOCAL_BIN:$PATH"

###############################################################################
# Verify PATH
###############################################################################

printf "\n"
info "Checking PATH..."

if [[ ":$PATH:" == *":$LOCAL_BIN:"* ]]; then
    success "$LOCAL_BIN is present in PATH."
else
    warning "$LOCAL_BIN is not currently in PATH."
    warning "It will be available after starting a new terminal."
fi

###############################################################################
# Verify JMeter Binary
###############################################################################

printf "\n"
info "Validating JMeter..."

if [[ ! -x "$JMETER_ROOT/bin/jmeter" ]]; then
    die "JMeter executable was not found."
fi

###############################################################################
# JMeter Version
###############################################################################

JMETER_VERSION_OUTPUT="$(
    "$JMETER_ROOT/bin/jmeter" --version 2>&1
)"

echo "$JMETER_VERSION_OUTPUT"

if "$JMETER_ROOT/bin/jmeter" --version >/dev/null 2>&1; then
    success "JMeter CLI is working."
else
    die "JMeter validation failed."
fi

###############################################################################
# Final Verification
###############################################################################

printf "\n"
printf "%b============================================================%b\n" "$GREEN" "$NC"
printf "%b Installation Completed Successfully%b\n" "$GREEN" "$NC"
printf "%b============================================================%b\n" "$GREEN" "$NC"

printf "\n"

echo "Operating System : macOS"
echo "Architecture     : $ARCH"
echo "Java             : $JAVA_HOME"
echo "JMeter           : $JMETER_HOME"
echo "JMeter Command   : $LOCAL_BIN/jmeter"

printf "\n"

echo "Java Version:"
"$JAVA_HOME/bin/java" -version 2>&1

printf "\n"

echo "JMeter Version:"
"$JMETER_ROOT/bin/jmeter" --version

printf "\n"

printf "%b============================================================%b\n" "$CYAN" "$NC"
printf "%b Next Steps%b\n" "$CYAN" "$NC"
printf "%b============================================================%b\n" "$CYAN" "$NC"

printf "\n"

echo "1. Reload your shell:"
echo
echo "   source ~/.zshrc"

printf "\n"

echo "2. Verify Java:"
echo
echo "   java -version"

printf "\n"

echo "3. Verify JMeter:"
echo
echo "   jmeter --version"

printf "\n"

echo "4. Launch JMeter GUI:"
echo
echo "   jmeter"

printf "\n"

echo "5. Run a test in CLI mode:"
echo
echo "   jmeter -n -t test.jmx -l results.jtl"

printf "\n"

echo "6. Generate HTML report:"
echo
echo "   jmeter -n -t test.jmx -l results.jtl -e -o report"

printf "\n"

echo "Installation location:"
echo
echo "   $INSTALL_ROOT"

printf "\n"

success "No sudo was used."
echo
