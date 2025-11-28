#!/bin/zsh
set -e

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  MVND_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-amd64.zip"
elif [ "$ARCH" = "arm64" ]; then
  MVND_URL="https://dlcdn.apache.org/maven/mvnd/1.0.3/maven-mvnd-1.0.3-darwin-aarch64.zip"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

echo "Detected architecture: $ARCH"
echo "Downloading mvnd from: $MVND_URL"

TMP=$(mktemp -d)
cd "$TMP"

curl -L -o mvnd.zip "$MVND_URL"

# check it's a valid zip
if ! file mvnd.zip | grep -q "Zip archive data"; then
  echo "Downloaded file is not a valid zip archive; aborting."
  exit 1
fi

echo "Unzipping..."
unzip mvnd.zip

# The zip unpacks to a folder, e.g. maven-mvnd-1.0.3
DIR_NAME="maven-mvnd-1.0.3"
TARGET="$HOME/Clitools/mvnd"

mkdir -p "$HOME/Clitools"
rm -rf "$TARGET"
mv "$DIR_NAME" "$TARGET"

echo "mvnd installed to: $TARGET"

# Update .zshrc
ZSHRC="$HOME/.zshrc"
EXPORT_LINE="export PATH=\"$TARGET/bin:\$PATH\""

if ! grep -q "Clitools/mvnd" "$ZSHRC"; then
  echo "" >> "$ZSHRC"
  echo "# Added by mvnd installer" >> "$ZSHRC"
  echo "$EXPORT_LINE" >> "$ZSHRC"
  echo ".zshrc updated with mvnd path."
else
  echo ".zshrc already has mvnd path — skipping."
fi

# Cleanup
cd ~
rm -rf "$TMP"

echo "Installation complete. Run: source ~/.zshrc"
