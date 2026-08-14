#!/bin/bash

###############################################################################
# Apache JMeter - macOS User-Level Installation
#
# Requirements:
#   - macOS
#   - Java/JDK must already be installed
#   - Java should be installed through Company Portal
#   - Standard user account
#
# Does NOT require:
#   - sudo
#   - Homebrew
#   - Administrator privileges
#
# Installation:
#   $HOME/CLI/jmeter
#   $HOME/.local/bin/jmeter
#
###############################################################################

set -uo pipefail

###############################################################################
# Configuration
###############################################################################

JMETER_VERSION="5.6.3"

INSTALL_ROOT="$HOME/CLI"
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
# Logging Functions
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
# Exit / Cleanup
###############################################################################

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

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
# Check macOS
###############################################################################

if [[ "$(uname -s)" != "Darwin" ]]; then
    die "This script supports macOS only."
fi

info "Detected macOS:"
sw_vers

printf "\n"

###############################################################################
# macOS Version
###############################################################################

MACOS_VERSION="$(sw_vers -productVersion)"

info "macOS version: $MACOS_VERSION"

###############################################################################
# Detect Architecture
###############################################################################

ARCH="$(uname -m)"

case "$ARCH" in

    arm64)
        info "Architecture detected: Apple Silicon (arm64)"
        ;;

    x86_64)
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
# Check Java
###############################################################################

printf "\n"
info "Checking Java installation..."

JAVA_HOME_VALUE=""

###############################################################################
# Method 1 - JAVA_HOME
###############################################################################

if [[ -n "${JAVA_HOME:-}" ]] &&
   [[ -x "$JAVA_HOME/bin/java" ]]; then

    JAVA_HOME_VALUE="$JAVA_HOME"

    success "JAVA_HOME is configured:"
    echo "       $JAVA_HOME_VALUE"

fi

###############################################################################
# Method 2 - macOS java_home
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    JAVA_HOME_DETECTED=""

    if JAVA_HOME_DETECTED="$(
        /usr/libexec/java_home 2>/dev/null
    )"; then

        if [[ -n "$JAVA_HOME_DETECTED" ]] &&
           [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

            JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

            success "Java installation detected:"
            echo "       $JAVA_HOME_VALUE"

        fi

    fi

fi

###############################################################################
# Method 3 - java command
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    if command -v java >/dev/null 2>&1; then

        JAVA_COMMAND="$(command -v java)"

        if [[ -x "$JAVA_COMMAND" ]]; then

            JAVA_HOME_DETECTED=""

            if JAVA_HOME_DETECTED="$(
                /usr/libexec/java_home 2>/dev/null
            )"; then

                if [[ -n "$JAVA_HOME_DETECTED" ]] &&
                   [[ -x "$JAVA_HOME_DETECTED/bin/java" ]]; then

                    JAVA_HOME_VALUE="$JAVA_HOME_DETECTED"

                fi

            fi

        fi

    fi

fi

###############################################################################
# Java NOT Installed
###############################################################################

if [[ -z "$JAVA_HOME_VALUE" ]]; then

    printf "\n"

    printf "%b============================================================%b\n" "$RED" "$NC"
    printf "%b Java is NOT Installed%b\n" "$RED" "$NC"
    printf "%b============================================================%b\n" "$RED" "$NC"

    printf "\n"

    echo "JMeter requires Java to be installed before continuing."
    echo
    echo "Please install Java using:"
    echo
    echo "    Company Portal"
    echo
    echo "Install:"
    echo
    echo "    Temurin Java / Eclipse Temurin"
    echo
    echo "After Java installation is completed:"
    echo
    echo "    1. Close this Terminal"
    echo "    2. Open a new Terminal"
    echo "    3. Run this JMeter installation script again"
    echo

    printf "%b============================================================%b\n" "$YELLOW" "$NC"
    printf "%b Installation stopped - Java is required.%b\n" "$YELLOW" "$NC"
    printf "%b============================================================%b\n" "$YELLOW" "$NC"
    printf "\n"

    exit 1

fi

###############################################################################
# Configure Java
###############################################################################

export JAVA_HOME="$JAVA_HOME_VALUE"
export PATH="$JAVA_HOME/bin:$PATH"

###############################################################################
# Display Java Version
###############################################################################

printf "\n"
info "Java installation found."

echo
echo "JAVA_HOME:"
echo "    $JAVA_HOME"

echo
echo "Java version:"

"$JAVA_HOME/bin/java" -version 2>&1

###############################################################################
# Validate Java
###############################################################################

JAVA_MAJOR_VERSION="$(
    "$JAVA_HOME/bin/java" -version 2>&1 |
    awk -F '"' '/version/ {print $2; exit}' |
    awk -F. '{print $1}'
)"

if [[ -z "$JAVA_MAJOR_VERSION" ]]; then
    warning "Unable to determine Java major version."
else
    info "Detected Java major version: $JAVA_MAJOR_VERSION"
fi

###############################################################################
# Create Installation Directories
###############################################################################

printf "\n"
info "Creating user-level installation directories..."

mkdir -p "$INSTALL_ROOT"
mkdir -p "$LOCAL_BIN"
mkdir -p "$TEMP_DIR"

success "Installation directories created."

###############################################################################
# JMeter Installation
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
# Validate Download
###############################################################################

if [[ ! -s "$JMETER_ARCHIVE" ]]; then
    die "Downloaded JMeter archive is empty."
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
# Remove Existing Installation
###############################################################################

if [[ -d "$JMETER_ROOT" ]]; then

    warning "Existing JMeter installation found:"
    echo "       $JMETER_ROOT"

    info "Removing existing installation..."

    rm -rf "$JMETER_ROOT"

fi

###############################################################################
# Install JMeter
###############################################################################

mv "$EXTRACT_DIR" "$JMETER_ROOT"

success "JMeter installed:"
echo "       $JMETER_ROOT"

###############################################################################
# Set Permissions
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
# Configure ~/.zshrc
###############################################################################

printf "\n"
info "Configuring shell environment..."

touch "$SHELL_RC"

###############################################################################
# Remove Previous JMeter Configuration
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
# Add Configuration
###############################################################################

cat >> "$SHELL_RC" <<EOF

# >>> JMeter User Installation >>>

export JAVA_HOME="$JAVA_HOME_VALUE"
export JMETER_HOME="$JMETER_ROOT"
export PATH="\$JAVA_HOME/bin:\$JMETER_HOME/bin:\$HOME/.local/bin:\$PATH"

# <<< JMeter User Installation <<<

EOF

success "~/.zshrc updated."

###############################################################################
# Configure Current Shell
###############################################################################

export JAVA_HOME="$JAVA_HOME_VALUE"
export JMETER_HOME="$JMETER_ROOT"
export PATH="$JAVA_HOME/bin:$JMETER_HOME/bin:$LOCAL_BIN:$PATH"

###############################################################################
# Validate JMeter
###############################################################################

printf "\n"
info "Validating JMeter installation..."

if [[ ! -x "$JMETER_ROOT/bin/jmeter" ]]; then
    die "JMeter executable was not found."
fi

###############################################################################
# JMeter Version
###############################################################################

echo
echo "JMeter version:"

"$JMETER_ROOT/bin/jmeter" --version

###############################################################################
# JMeter CLI Test
###############################################################################

if "$JMETER_ROOT/bin/jmeter" --version >/dev/null 2>&1; then
    success "JMeter CLI is working."
else
    die "JMeter CLI validation failed."
fi

###############################################################################
# Final Output
###############################################################################

printf "\n"
printf "%b============================================================%b\n" "$GREEN" "$NC"
printf "%b JMeter Installation Completed Successfully%b\n" "$GREEN" "$NC"
printf "%b============================================================%b\n" "$GREEN" "$NC"

printf "\n"

echo "Operating System : macOS"
echo "Architecture     : $ARCH"
echo "Java             : $JAVA_HOME"
echo "JMeter           : $JMETER_HOME"
echo "JMeter Command   : $LOCAL_BIN/jmeter"

printf "\n"

echo "Next steps:"
echo
echo "1. Reload your shell:"
echo
echo "   source ~/.zshrc"
echo
echo "2. Verify Java:"
echo
echo "   java -version"
echo
echo "3. Verify JMeter:"
echo
echo "   jmeter --version"
echo
echo "4. Launch JMeter:"
echo
echo "   jmeter"
echo
echo "5. Run JMeter in CLI mode:"
echo
echo "   jmeter -n -t test.jmx -l results.jtl"
echo
echo "6. Generate HTML report:"
echo
echo "   jmeter -n -t test.jmx -l results.jtl -e -o report"

printf "\n"

success "Installation completed without sudo."

printf "\n"
