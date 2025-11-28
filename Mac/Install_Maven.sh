#!/bin/zsh
set -e

# Detect architecture (not required by Maven, but you asked for it)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CPU="Intel"
elif [ "$ARCH" = "arm64" ]; then
    CPU="Apple Silicon"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected: $CPU"

# Maven version to install (latest stable as of now)
MAVEN_VERSION="3.9.9"
MAVEN_TAR="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_TAR}"

# Prepare workspace
TMP=$(mktemp -d)
cd "$TMP"

echo "Downloading Maven ${MAVEN_VERSION}..."
curl -L -o maven.tar.gz "$MAVEN_URL"

file maven.tar.gz | grep -q "gzip compressed data" || {
    echo "Download failed or invalid archive"; exit 1;
}

echo "Extracting..."
tar -xzf maven.tar.gz

# Install directory
TARGET_BASE="$HOME/Clitools"
TARGET_DIR="$TARGET_BASE/maven"

mkdir -p "$TARGET_BASE"
rm -rf "$TARGET_DIR"

mv "apache-maven-${MAVEN_VERSION}" "$TARGET_DIR"

echo "Maven installed at: $TARGET_DIR"

# Update .zshrc
ZSHRC="$HOME/.zshrc"
M2_HOME_LINE='export M2_HOME="$HOME/Clitools/maven"'
MAVEN_PATH_LINE='export PATH="$M2_HOME/bin:$PATH"'

if ! grep -q 'Clitools/maven' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Maven setup added by installer" >> "$ZSHRC"
    echo "$M2_HOME_LINE" >> "$ZSHRC"
    echo "$MAVEN_PATH_LINE" >> "$ZSHRC"
    echo ".zshrc updated."
else
    echo ".zshrc already contains Maven path. Skipped."
fi

# Cleanup
cd ~
rm -rf "$TMP"

echo "Done. Run: source ~/.zshrc"
