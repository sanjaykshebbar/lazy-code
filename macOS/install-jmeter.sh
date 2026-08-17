#!/usr/bin/env bash
# Description: Apache JMeter on macOS - no sudo, no Homebrew, with a Java check
# Platform: macOS
###############################################################################
# Installs Apache JMeter into $HOME/CLI/jmeter.
#
# No sudo and no Homebrew: everything lands under your home directory.
#
# What it does:
#   1. Checks for a usable Java (JMeter needs Java 8+); offers to install a
#      Temurin JDK 21 into $HOME if none is found.
#   2. Resolves the current JMeter release from the Apache mirror.
#   3. Downloads it and verifies the SHA-512 published by Apache.
#   4. Extracts to $HOME/CLI/jmeter, replacing any previous install.
#   5. Adds it to PATH in whichever shell rc your shell actually reads.
###############################################################################
set -euo pipefail

INSTALL_DIR="$HOME/CLI"
FINAL_DIR="$INSTALL_DIR/jmeter"
JDK_DIR="$INSTALL_DIR/jdk"

MIRROR="https://downloads.apache.org/jmeter/binaries"
ARCHIVE_MIRROR="https://archive.apache.org/dist/jmeter/binaries"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

###############################################################################
# Output helpers
#
# A previous revision of this script called info/success/die without ever
# defining them, so it aborted with "info: command not found". They are defined
# here.
###############################################################################

if [ -t 1 ]; then
    GREEN=$'\033[1;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[1;31m'; NC=$'\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; NC=''
fi

info()    { printf '%s==>%s %s\n' "$GREEN"  "$NC" "$1"; }
warn()    { printf '%s==>%s %s\n' "$YELLOW" "$NC" "$1" >&2; }
success() { printf '%s✓%s %s\n'   "$GREEN"  "$NC" "$1"; }
die()     { printf '%sERROR:%s %s\n' "$RED" "$NC" "$1" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is required but was not found."; }
need curl
need tar

###############################################################################
# Shell rc detection
###############################################################################

detect_rc() {
    case "$(basename "${SHELL:-/bin/zsh}")" in
        zsh)  echo "$HOME/.zshrc"  ;;
        bash) echo "$HOME/.bash_profile" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}
RC_FILE="$(detect_rc)"

# Append only if absent, so re-running does not stack duplicate PATH entries.
add_line() {
    touch "$RC_FILE"
    grep -qxF "$1" "$RC_FILE" || echo "$1" >> "$RC_FILE"
}

###############################################################################
# Java
###############################################################################

find_java() {
    if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        echo "$JAVA_HOME"; return 0
    fi
    if [ -x "$JDK_DIR/Contents/Home/bin/java" ]; then
        echo "$JDK_DIR/Contents/Home"; return 0
    fi
    # /usr/libexec/java_home exits non-zero when no JDK is registered.
    local detected
    if detected="$(/usr/libexec/java_home 2>/dev/null)" \
       && [ -n "$detected" ] && [ -x "$detected/bin/java" ]; then
        echo "$detected"; return 0
    fi
    return 1
}

install_java() {
    local arch url
    case "$(uname -m)" in
        arm64)  arch="aarch64" ;;
        x86_64) arch="x64"     ;;
        *) die "Unsupported architecture: $(uname -m)" ;;
    esac

    info "Installing Temurin JDK 21 into $JDK_DIR (no sudo)..."
    url="https://api.adoptium.net/v3/binary/latest/21/ga/mac/${arch}/jdk/hotspot/normal/eclipse"

    curl -fsSL "$url" -o "$TMP_DIR/jdk.tar.gz" || die "Failed to download the JDK."

    rm -rf "$JDK_DIR"
    mkdir -p "$JDK_DIR"
    tar -xzf "$TMP_DIR/jdk.tar.gz" -C "$JDK_DIR" --strip-components=1

    [ -x "$JDK_DIR/Contents/Home/bin/java" ] \
        || die "The JDK archive did not unpack as expected."

    add_line "export JAVA_HOME=\"$JDK_DIR/Contents/Home\""
    echo "$JDK_DIR/Contents/Home"
}

info "Checking for Java..."
if JAVA_HOME_VALUE="$(find_java)"; then
    success "Java found: $JAVA_HOME_VALUE"
else
    warn "No Java installation found. JMeter requires Java 8 or newer."
    JAVA_HOME_VALUE="$(install_java)"
    success "Java installed: $JAVA_HOME_VALUE"
fi

export JAVA_HOME="$JAVA_HOME_VALUE"
export PATH="$JAVA_HOME/bin:$PATH"

"$JAVA_HOME/bin/java" -version >/dev/null 2>&1 \
    || die "Java was found at $JAVA_HOME but could not be executed."

info "Using: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"

###############################################################################
# Resolve the current JMeter release
#
# The version is not hardcoded: Apache removes superseded releases from
# downloads.apache.org (they move to archive.apache.org), which is exactly how
# the Maven script in this repo ended up 404-ing.
###############################################################################

info "Resolving the current JMeter release..."

VERSION="$(
    curl -fsSL "$MIRROR/" \
        | grep -oE 'apache-jmeter-[0-9]+\.[0-9]+(\.[0-9]+)?\.tgz' \
        | sed -E 's/apache-jmeter-(.*)\.tgz/\1/' \
        | sort -u -V \
        | tail -1
)" || true

[ -n "$VERSION" ] || die "Could not determine the current JMeter version from $MIRROR."

TARBALL="apache-jmeter-${VERSION}.tgz"
info "Latest release: JMeter $VERSION"

###############################################################################
# Download + verify
###############################################################################

BASE_URL="$MIRROR"
if ! curl -fsSL --head "$MIRROR/$TARBALL" >/dev/null 2>&1; then
    warn "$TARBALL is not on the primary mirror; falling back to the archive."
    BASE_URL="$ARCHIVE_MIRROR"
fi

info "Downloading $TARBALL..."
curl -fSL --progress-bar "$BASE_URL/$TARBALL" -o "$TMP_DIR/$TARBALL" \
    || die "Download failed."

# Apache publishes "<sha512>  *<filename>"; take the first field.
info "Verifying checksum..."
if EXPECTED="$(curl -fsSL "$BASE_URL/$TARBALL.sha512" 2>/dev/null | awk '{print $1}')" \
   && [ -n "$EXPECTED" ]; then
    ACTUAL="$(shasum -a 512 "$TMP_DIR/$TARBALL" | awk '{print $1}')"
    if [ "$EXPECTED" != "$ACTUAL" ]; then
        die "Checksum mismatch - the download may be corrupt or tampered with.
  expected: $EXPECTED
  actual:   $ACTUAL"
    fi
    success "Checksum verified."
else
    warn "Checksum file unavailable - continuing without verification."
fi

###############################################################################
# Install
###############################################################################

info "Extracting to $FINAL_DIR..."
mkdir -p "$INSTALL_DIR"

# Take the top-level directory name from the archive rather than assuming it
# matches the version string.
EXTRACTED="$(tar -tzf "$TMP_DIR/$TARBALL" | head -1 | cut -f1 -d/)"
[ -n "$EXTRACTED" ] || die "Could not read the archive layout."

rm -rf "$TMP_DIR/unpack"
mkdir -p "$TMP_DIR/unpack"
tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR/unpack"

# Only remove the previous install once the new one has unpacked cleanly.
rm -rf "$FINAL_DIR"
mv "$TMP_DIR/unpack/$EXTRACTED" "$FINAL_DIR"

chmod +x "$FINAL_DIR/bin/jmeter" 2>/dev/null || true

###############################################################################
# PATH
###############################################################################

add_line 'export PATH="$HOME/CLI/jmeter/bin:$PATH"'
export PATH="$FINAL_DIR/bin:$PATH"

###############################################################################
# Verify
###############################################################################

info "Verifying installation..."
"$FINAL_DIR/bin/jmeter" --version 2>&1 | head -5 \
    || die "JMeter was installed but did not run."

cat <<EOF

$(success "Apache JMeter $VERSION installed.")

  Location:  $FINAL_DIR
  PATH set:  $RC_FILE

Open a new terminal, or run:  source "$RC_FILE"
Then start it with:           jmeter        (GUI)
                              jmeter -n -t plan.jmx -l out.jtl   (CLI)
EOF
