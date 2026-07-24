#!/usr/bin/env bash
# SentinelOps PC Agent — one-line installer (macOS / Linux).
# Hosted at: https://github.com/sanjaykshebbar/lazy-code/tree/main/SentinelOps
#
#   curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.sh \
#        | sudo bash -s -- <server-url> <enrollment-token>
set -euo pipefail

SERVER="${1:?usage: install.sh <server-url> <enrollment-token>}"
TOKEN="${2:?usage: install.sh <server-url> <enrollment-token>}"
SERVER="${SERVER%/}"
AGENT_URL="${SO_AGENT_URL:-https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/agent.mjs}"

command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js 18+ is required on this machine (https://nodejs.org)."; exit 1; }
NODE="$(command -v node)"

if [ "$(id -u)" -eq 0 ]; then DEST="/opt/sentinelops-agent"; CONF_DIR="/etc/sentinelops"; LOG="/var/log/sentinelops-agent.log";
else DEST="$HOME/.sentinelops-agent-app"; CONF_DIR="$HOME/.config/sentinelops"; LOG="$HOME/.config/sentinelops/agent.log"; fi
CONF="$CONF_DIR/agent.json"
mkdir -p "$DEST" "$CONF_DIR"

echo "Downloading agent from $AGENT_URL …"
curl -fsSL "$AGENT_URL" -o "$DEST/agent.mjs"

printf '{\n  "serverUrl": "%s",\n  "enrollToken": "%s"\n}\n' "$SERVER" "$TOKEN" > "$CONF"
chmod 600 "$CONF"

if [ "$(id -u)" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
  cat > /etc/systemd/system/sentinelops-agent.service <<UNIT
[Unit]
Description=SentinelOps PC Agent
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
Environment=SO_CONFIG=$CONF
Environment=SO_LOG=$LOG
ExecStart=$NODE $DEST/agent.mjs
Restart=always
RestartSec=30
[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload
  systemctl enable --now sentinelops-agent.service
  echo "Installed as systemd service. Logs: journalctl -u sentinelops-agent -f"
elif [ "$(id -u)" -eq 0 ] && [ "$(uname)" = "Darwin" ]; then
  PLIST="/Library/LaunchDaemons/com.sentinelops.agent.plist"
  cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.sentinelops.agent</string>
  <key>ProgramArguments</key><array><string>$NODE</string><string>$DEST/agent.mjs</string></array>
  <key>EnvironmentVariables</key><dict><key>SO_CONFIG</key><string>$CONF</string><key>SO_LOG</key><string>$LOG</string></dict>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$LOG</string><key>StandardErrorPath</key><string>$LOG</string>
</dict></plist>
PLIST
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load -w "$PLIST"
  echo "Installed as launchd daemon (com.sentinelops.agent). Log: $LOG"
else
  echo "Enrolling this device now…"
  SO_CONFIG="$CONF" "$NODE" "$DEST/agent.mjs" --once
  echo
  echo "Run continuously with:  SO_CONFIG=$CONF $NODE $DEST/agent.mjs"
  echo "(Re-run this installer as root to register it as a background service.)"
fi
