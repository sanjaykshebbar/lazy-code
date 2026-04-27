#!/bin/bash
###############################################################################
# Rize.io - Production Grade Uninstall Script for Microsoft Intune
# Supports: macOS Intel + Apple Silicon
# Features:
# - Logging
# - Error handling
# - Retries
# - Safe process termination
# - User artifact cleanup
# - Exit codes for Intune reporting
###############################################################################

############################
# Configuration
############################
APP_NAME="Rize"
APP_PROCESS="Rize"
APP_BUNDLE="/Applications/Rize.app"

LOG_DIR="/Library/Logs/Company"
LOG_FILE="$LOG_DIR/rize_uninstall.log"

MAX_RETRIES=3
SLEEP_BETWEEN_RETRIES=3

############################
# Logging
############################
mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

############################
# Validation
############################
if [[ $EUID -ne 0 ]]; then
    echo "This script must run as root."
    exit 1
fi

ARCH=$(uname -m)
log "================================================="
log "Starting uninstall for $APP_NAME"
log "Detected architecture: $ARCH"

############################
# Retry Function
############################
retry_cmd() {
    local CMD="$1"
    local COUNT=1

    while [[ $COUNT -le $MAX_RETRIES ]]; do
        eval "$CMD"
        local RC=$?

        if [[ $RC -eq 0 ]]; then
            return 0
        fi

        log "Attempt $COUNT failed for command: $CMD"
        sleep "$SLEEP_BETWEEN_RETRIES"
        COUNT=$((COUNT+1))
    done

    return 1
}

############################
# Stop App Processes
############################
log "Stopping running processes..."

pkill -x "$APP_PROCESS" 2>/dev/null
sleep 2

if pgrep -x "$APP_PROCESS" >/dev/null; then
    log "Graceful stop failed. Forcing termination..."
    pkill -9 -x "$APP_PROCESS" 2>/dev/null
fi

############################
# Remove Main App
############################
if [[ -d "$APP_BUNDLE" ]]; then
    log "Removing app bundle..."

    retry_cmd "rm -rf \"$APP_BUNDLE\""

    if [[ $? -ne 0 ]]; then
        log "ERROR: Failed to remove $APP_BUNDLE"
        exit 2
    fi
else
    log "App bundle not present. Continuing..."
fi

############################
# Remove User Data
############################
log "Removing user-level artifacts..."

for USER_HOME in /Users/*; do
    [[ ! -d "$USER_HOME" ]] && continue

    USERNAME=$(basename "$USER_HOME")

    # Skip Shared folder
    [[ "$USERNAME" == "Shared" ]] && continue

    log "Cleaning user data for $USERNAME"

    rm -rf "$USER_HOME/Library/Application Support/Rize" 2>/dev/null
    rm -rf "$USER_HOME/Library/Caches/io.rize.app" 2>/dev/null
    rm -rf "$USER_HOME/Library/Preferences/io.rize.app.plist" 2>/dev/null
    rm -rf "$USER_HOME/Library/Saved Application State/io.rize.app.savedState" 2>/dev/null
    rm -rf "$USER_HOME/Library/Logs/Rize" 2>/dev/null
done

############################
# Remove Launch Agents / Daemons
############################
log "Checking LaunchAgents / LaunchDaemons..."

find /Library/LaunchAgents -iname "*rize*" -exec rm -f {} \; 2>/dev/null
find /Library/LaunchDaemons -iname "*rize*" -exec rm -f {} \; 2>/dev/null

############################
# Forget Installer Receipts
############################
log "Checking pkg receipts..."

pkgutil --pkgs | grep -i rize | while read PKG; do
    log "Forgetting receipt: $PKG"
    pkgutil --forget "$PKG" >/dev/null 2>&1
done

############################
# Final Verification
############################
if [[ -d "$APP_BUNDLE" ]]; then
    log "ERROR: Uninstall incomplete. App still exists."
    exit 3
fi

log "Uninstall completed successfully."
log "================================================="

exit 0
