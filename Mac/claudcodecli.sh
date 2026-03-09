#!/usr/bin/env bash

set -e

TARGET="$1"

if [[ -n "$TARGET" ]] && [[ ! "$TARGET" =~ ^(stable|latest|[0-9]+\.[0-9]+\.[0-9]+(-[^[:space:]]+)?)$ ]]; then
    echo "Usage: $0 [stable|latest|VERSION]" >&2
    exit 1
fi

GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

INSTALL_DIR="$HOME/CLI"
DOWNLOAD_DIR="$HOME/CLI/.downloads"

mkdir -p "$INSTALL_DIR"
mkdir -p "$DOWNLOAD_DIR"

# Detect downloader
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "curl or wget required" >&2
    exit 1
fi

# jq optional
HAS_JQ=false
command -v jq >/dev/null 2>&1 && HAS_JQ=true

download_file() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOADER" = "curl" ]; then
        if [ -n "$output" ]; then
            curl -fsSL -o "$output" "$url"
        else
            curl -fsSL "$url"
        fi
    else
        if [ -n "$output" ]; then
            wget -q -O "$output" "$url"
        else
            wget -q -O - "$url"
        fi
    fi
}

get_checksum_from_manifest() {
    local json="$1"
    local platform="$2"

    json=$(echo "$json" | tr -d '\n\r\t')

    if [[ $json =~ \"$platform\"[^}]*\"checksum\"[[:space:]]*:[[:space:]]*\"([a-f0-9]{64})\" ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Detect OS
case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *) echo "Unsupported OS"; exit 1 ;;
esac

# Detect architecture
case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "Unsupported architecture"; exit 1 ;;
esac

# Rosetta detection
if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
        arch="arm64"
    fi
fi

platform="${os}-${arch}"

# Get latest version
version=$(download_file "$GCS_BUCKET/latest")

manifest_json=$(download_file "$GCS_BUCKET/$version/manifest.json")

if [ "$HAS_JQ" = true ]; then
    checksum=$(echo "$manifest_json" | jq -r ".platforms[\"$platform\"].checksum")
else
    checksum=$(get_checksum_from_manifest "$manifest_json" "$platform")
fi

if [ -z "$checksum" ]; then
    echo "Platform not found in manifest"
    exit 1
fi

binary_path="$DOWNLOAD_DIR/claude-$version-$platform"

download_file "$GCS_BUCKET/$version/$platform/claude" "$binary_path"

# Verify checksum
actual=$(shasum -a 256 "$binary_path" | awk '{print $1}')

if [ "$actual" != "$checksum" ]; then
    echo "Checksum verification failed"
    rm -f "$binary_path"
    exit 1
fi

chmod +x "$binary_path"

mv "$binary_path" "$INSTALL_DIR/claude"

rm -rf "$DOWNLOAD_DIR"

echo ""
echo "Installation complete."
echo ""
echo "Binary installed at:"
echo "$HOME/CLI/claude"
echo ""

echo "To run:"
echo "$HOME/CLI/claude"
