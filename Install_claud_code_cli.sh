#!/usr/bin/env bash
set -e

TARGET="$1"

BASE_DIR="$HOME/cli"
BIN_DIR="$BASE_DIR/bin"
DOWNLOAD_DIR="$BASE_DIR/.downloads"

mkdir -p "$BIN_DIR" "$DOWNLOAD_DIR"

GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

########################################
# downloader
########################################
if command -v curl >/dev/null 2>&1; then
    dl() { curl -fsSL "$1" -o "$2"; }
    dl_text() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
    dl() { wget -q -O "$2" "$1"; }
    dl_text() { wget -q -O - "$1"; }
else
    echo "curl or wget required"; exit 1
fi

########################################
# platform detect
########################################
case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *) echo "Unsupported OS"; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "Unsupported arch"; exit 1 ;;
esac

# musl detection
if [ "$os" = "linux" ]; then
    if ldd /bin/ls 2>&1 | grep -q musl; then
        platform="linux-${arch}-musl"
    else
        platform="linux-${arch}"
    fi
else
    platform="${os}-${arch}"
fi

########################################
# get version
########################################
version=$(dl_text "$GCS_BUCKET/latest")

manifest=$(dl_text "$GCS_BUCKET/$version/manifest.json")

checksum=$(echo "$manifest" | \
grep -A3 "\"$platform\"" | \
grep checksum | \
cut -d'"' -f4)

[ -z "$checksum" ] && { echo "Platform not supported"; exit 1; }

########################################
# download binary
########################################
binary="$DOWNLOAD_DIR/claude-$version"

echo "Downloading Claude CLI $version ($platform)"
dl "$GCS_BUCKET/$version/$platform/claude" "$binary"

########################################
# verify
########################################
if [ "$os" = "darwin" ]; then
    actual=$(shasum -a 256 "$binary" | awk '{print $1}')
else
    actual=$(sha256sum "$binary" | awk '{print $1}')
fi

[ "$actual" != "$checksum" ] && { echo "Checksum failed"; exit 1; }

chmod +x "$binary"

########################################
# install locally
########################################
install_path="$BIN_DIR/claude"
mv "$binary" "$install_path"

########################################
# path setup
########################################
add_path() {
    rc="$1"
    [ -f "$rc" ] || return
    if ! grep -q 'cli/bin' "$rc"; then
        echo 'export PATH="$HOME/cli/bin:$PATH"' >> "$rc"
    fi
}

add_path "$HOME/.bashrc"
add_path "$HOME/.zshrc"
add_path "$HOME/.profile"

export PATH="$HOME/cli/bin:$PATH"

########################################
# done
########################################
echo ""
echo "Installed to: $install_path"
echo "Run: claude --help"
