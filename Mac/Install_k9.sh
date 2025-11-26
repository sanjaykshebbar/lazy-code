#!/bin/zsh
set -e

# Use fixed download URL
URL="https://github.com/derailed/k9s/releases/download/v0.50.16/k9s_Darwin_amd64.tar.gz"

TMP=$(mktemp -d)
cd "$TMP"

echo "Downloading K9s..."
curl -L -o k9s.tar.gz "$URL"

file k9s.tar.gz | grep -q "gzip compressed data" || { echo "Download failed or invalid archive"; exit 1; }

echo "Extracting..."
tar -xzf k9s.tar.gz

mkdir -p "$HOME/Clitools/k9s"
mv k9s "$HOME/Clitools/k9s/"
chmod +x "$HOME/Clitools/k9s/k9s"
echo "Installed k9s to $HOME/Clitools/k9s/k9s"

ZSHRC="$HOME/.zshrc"
LINE='export PATH="$HOME/Clitools/k9s:$PATH"'
if ! grep -q 'Clitools/k9s' "$ZSHRC"; then
  echo "" >> "$ZSHRC"
  echo "# added by k9s installer" >> "$ZSHRC"
  echo "$LINE" >> "$ZSHRC"
  echo "Updated .zshrc"
else
  echo ".zshrc already updated"
fi

cd ~
rm -rf "$TMP"
echo "Done. Please run: source ~/.zshrc"
