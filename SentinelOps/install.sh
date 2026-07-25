#!/usr/bin/env bash
# SentinelOps Agent — one-line installer (macOS; Linux service install not yet
# supported, see below).
# Hosted at: https://github.com/sanjaykshebbar/lazy-code/tree/main/SentinelOps
#
#   curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.sh \
#        | sudo bash -s -- <server-url> <enrollment-token>
#
# Downloads the standalone SentinelOps agent (a single static binary — no runtime
# dependency) and installs it as a launchd daemon. Must be run as root (sudo).
set -euo pipefail

SERVER="${1:?usage: install.sh <server-url> <enrollment-token>}"
TOKEN="${2:?usage: install.sh <server-url> <enrollment-token>}"
SERVER="${SERVER%/}"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Darwin" ]; then
  echo "ERROR: this installer currently supports macOS only." >&2
  echo "Linux service installation is not implemented yet — track progress at:" >&2
  echo "  https://github.com/sanjaykshebbar/SentinalOps" >&2
  exit 1
fi

case "$ARCH" in
  arm64)  PLATFORM="darwin-arm64" ;;
  x86_64) PLATFORM="darwin-amd64" ;;
  *) echo "ERROR: unsupported architecture $ARCH" >&2; exit 1 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run this installer with sudo (installing a launchd daemon requires root)." >&2
  exit 1
fi

BIN_URL="${SO_BIN_URL:-https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/bin/$PLATFORM/sentinelops-agent}"
TMP_BIN="$(mktemp)"
trap 'rm -f "$TMP_BIN"' EXIT

echo "Downloading agent from $BIN_URL …"
curl -fsSL "$BIN_URL" -o "$TMP_BIN"
chmod +x "$TMP_BIN"

"$TMP_BIN" install -server "$SERVER" -token "$TOKEN"
