#!/usr/bin/env bash
# Description: Apache Maven, plus a JDK if one is missing - no sudo required
# Platform: Linux
set -euo pipefail

# ---------------------------------------------------------------------------
# Installs into $HOME/cli/maven so no root access is needed.
#
# Previous versions of this script hardcoded Maven 3.9.9, which Apache has since
# removed from dlcdn.apache.org (404). The version is now resolved at runtime
# from the download mirror, so this will not rot again.
# ---------------------------------------------------------------------------

BASE_DIR="$HOME/cli"
MAVEN_DIR="$BASE_DIR/maven"
JDK_DIR="$BASE_DIR/jdk"
MIRROR="https://dlcdn.apache.org/maven/maven-3"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

info() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed."; }
need curl
need tar

# --- pick the shell rc file that will actually be read -----------------------
# The old script always wrote to ~/.zshrc, so on a default Ubuntu box (bash)
# the PATH export was silently never applied.
detect_rc() {
    case "$(basename "${SHELL:-/bin/bash}")" in
        zsh)  echo "$HOME/.zshrc"  ;;
        bash) echo "$HOME/.bashrc" ;;
        *)    echo "$HOME/.profile";;
    esac
}
RC_FILE="$(detect_rc)"

# Append a line only if it is not already present, so re-running does not
# stack up duplicate PATH entries.
add_line() {
    local line="$1"
    touch "$RC_FILE"
    grep -qxF "$line" "$RC_FILE" || echo "$line" >> "$RC_FILE"
}

# --- Java --------------------------------------------------------------------
install_java() {
    info "No JDK found. Installing Temurin JDK 21 (LTS) into $JDK_DIR..."
    local arch url
    case "$(uname -m)" in
        x86_64|amd64) arch="x64"   ;;
        aarch64|arm64) arch="aarch64" ;;
        *) die "Unsupported architecture: $(uname -m)" ;;
    esac

    # Adoptium's API always points at the current LTS build.
    url="https://api.adoptium.net/v3/binary/latest/21/ga/linux/${arch}/jdk/hotspot/normal/eclipse"
    curl -fsSL "$url" -o "$TMP_DIR/jdk.tar.gz" || die "Failed to download the JDK."

    mkdir -p "$JDK_DIR"
    tar -xzf "$TMP_DIR/jdk.tar.gz" -C "$JDK_DIR" --strip-components=1

    add_line "export JAVA_HOME=\"$JDK_DIR\""
    add_line "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
    export JAVA_HOME="$JDK_DIR"
    export PATH="$JAVA_HOME/bin:$PATH"
    info "JDK installed."
}

check_java() {
    if command -v java >/dev/null 2>&1; then
        info "Java found: $(java -version 2>&1 | head -1)"
    elif [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        info "Java found via JAVA_HOME: $JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        install_java
    fi
}

# --- Maven -------------------------------------------------------------------
resolve_maven_version() {
    # Newest 3.9.x that actually has a downloadable binary. Directories for
    # not-yet-released versions (e.g. 3.10.0) exist but are empty, so the
    # candidate is verified before use.
    local candidates v
    candidates=$(curl -fsSL "$MIRROR/" \
        | grep -oE '3\.[0-9]+\.[0-9]+' \
        | sort -u -V -r)
    [ -n "$candidates" ] || die "Could not read the Maven version list from $MIRROR."

    for v in $candidates; do
        if curl -fsSL --head "$MIRROR/$v/binaries/apache-maven-$v-bin.tar.gz" >/dev/null 2>&1; then
            echo "$v"
            return 0
        fi
    done
    die "No downloadable Maven release found on the mirror."
}

install_maven() {
    local version url
    info "Resolving the current Maven release..."
    version="$(resolve_maven_version)"
    info "Installing Maven $version into $MAVEN_DIR..."

    url="$MIRROR/$version/binaries/apache-maven-$version-bin.tar.gz"
    curl -fsSL "$url" -o "$TMP_DIR/maven.tar.gz" || die "Failed to download Maven $version."

    rm -rf "$MAVEN_DIR"
    mkdir -p "$MAVEN_DIR"
    tar -xzf "$TMP_DIR/maven.tar.gz" -C "$MAVEN_DIR" --strip-components=1

    add_line "export M2_HOME=\"$MAVEN_DIR\""
    add_line "export PATH=\"\$M2_HOME/bin:\$PATH\""
    export M2_HOME="$MAVEN_DIR"
    export PATH="$M2_HOME/bin:$PATH"
}

mkdir -p "$BASE_DIR"
check_java
install_maven

info "Verifying..."
"$MAVEN_DIR/bin/mvn" -version

cat <<EOF

Maven is installed at: $MAVEN_DIR
PATH updated in:       $RC_FILE

Open a new terminal, or run:  source "$RC_FILE"
EOF
