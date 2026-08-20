#!/bin/bash

set -u

# ============================================================
# Microsoft Teams - Complete macOS Cleanup & Reinstall Prep
# ============================================================

SCRIPT_NAME="Microsoft Teams Cleanup"
VERSION="1.0"

echo ""
echo "============================================================"
echo " $SCRIPT_NAME"
echo " Version: $VERSION"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# 1. Check macOS
# ------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "[ERROR] This script must be run on macOS."
    exit 1
fi

echo "[OK] macOS detected"

# ------------------------------------------------------------
# 2. Detect architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

case "$ARCH" in
    arm64)
        echo "[INFO] Architecture: Apple Silicon (arm64)"
        ;;
    x86_64)
        echo "[INFO] Architecture: Intel (x86_64)"
        ;;
    *)
        echo "[WARN] Unknown architecture: $ARCH"
        ;;
esac

# ------------------------------------------------------------
# 3. Detect logged-in user
# ------------------------------------------------------------

CURRENT_USER="$(stat -f '%Su' /dev/console)"

if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    echo "[ERROR] Could not determine logged-in console user."
    exit 1
fi

USER_HOME="$(dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"

if [[ -z "$USER_HOME" ]]; then
    USER_HOME="/Users/$CURRENT_USER"
fi

echo "[INFO] Logged-in user: $CURRENT_USER"
echo "[INFO] Home directory: $USER_HOME"

# ------------------------------------------------------------
# 4. Helper function
# ------------------------------------------------------------

remove_path() {

    local TARGET="$1"

    if [[ -e "$TARGET" || -L "$TARGET" ]]; then

        echo "[REMOVE] $TARGET"

        rm -rf "$TARGET" 2>/dev/null

        if [[ -e "$TARGET" || -L "$TARGET" ]]; then

            echo "[INFO] Permission required: $TARGET"

            sudo rm -rf "$TARGET" 2>/dev/null

            if [[ -e "$TARGET" || -L "$TARGET" ]]; then
                echo "[WARN] Could not remove: $TARGET"
            else
                echo "[OK] Removed"
            fi

        else
            echo "[OK] Removed"
        fi

    fi
}

# ------------------------------------------------------------
# 5. Stop Teams processes
# ------------------------------------------------------------

echo ""
echo "[1/8] Stopping Microsoft Teams processes..."

PROCESS_LIST=(
    "Microsoft Teams"
    "Microsoft Teams Helper"
    "Microsoft Teams Helper (GPU)"
    "Microsoft Teams Helper (Plugin)"
    "Microsoft Teams WebView"
    "Teams"
)

for PROCESS in "${PROCESS_LIST[@]}"; do
    killall "$PROCESS" 2>/dev/null || true
done

# Kill remaining processes matching Teams

pkill -if "Microsoft Teams" 2>/dev/null || true
pkill -if "msteams" 2>/dev/null || true

sleep 2

echo "[OK] Teams processes stopped"

# ------------------------------------------------------------
# 6. Remove Teams application
# ------------------------------------------------------------

echo ""
echo "[2/8] Removing Teams application..."

APP_PATHS=(
    "/Applications/Microsoft Teams.app"
    "$USER_HOME/Applications/Microsoft Teams.app"
)

for APP in "${APP_PATHS[@]}"; do
    remove_path "$APP"
done

# ------------------------------------------------------------
# 7. Remove Teams user data
# ------------------------------------------------------------

echo ""
echo "[3/8] Removing Teams user data..."

USER_PATHS=(
    "$USER_HOME/Library/Application Support/Microsoft/Teams"
    "$USER_HOME/Library/Application Support/Microsoft Teams"

    "$USER_HOME/Library/Caches/com.microsoft.teams"
    "$USER_HOME/Library/Caches/com.microsoft.teams2"

    "$USER_HOME/Library/Logs/Microsoft Teams"

    "$USER_HOME/Library/Preferences/com.microsoft.teams.plist"
    "$USER_HOME/Library/Preferences/com.microsoft.teams2.plist"

    "$USER_HOME/Library/Saved Application State/com.microsoft.teams.savedState"
    "$USER_HOME/Library/Saved Application State/com.microsoft.teams2.savedState"
)

for PATH_ITEM in "${USER_PATHS[@]}"; do
    remove_path "$PATH_ITEM"
done

# ------------------------------------------------------------
# 8. Remove sandbox containers / group containers
# ------------------------------------------------------------

echo ""
echo "[4/8] Removing Teams containers..."

CONTAINER_PATHS=(
    "$USER_HOME/Library/Containers/com.microsoft.teams"
    "$USER_HOME/Library/Containers/com.microsoft.teams2"

    "$USER_HOME/Library/Group Containers/UBF8T346G9.com.microsoft.teams"
    "$USER_HOME/Library/Group Containers/UBF8T346G9.com.microsoft.teams2"
)

for PATH_ITEM in "${CONTAINER_PATHS[@]}"; do
    remove_path "$PATH_ITEM"
done

# ------------------------------------------------------------
# 9. Remove Teams temporary files
# ------------------------------------------------------------

echo ""
echo "[5/8] Cleaning temporary Teams files..."

TMP_PATHS=(
    "/tmp/Microsoft Teams"
    "/tmp/msteams"
)

for PATH_ITEM in "${TMP_PATHS[@]}"; do
    remove_path "$PATH_ITEM"
done

# ------------------------------------------------------------
# 10. Keychain detection
# ------------------------------------------------------------

echo ""
echo "[6/8] Checking Keychain for Teams credentials..."

echo ""
echo "------------------------------------------------------------"
echo " Teams-related Keychain entries found:"
echo "------------------------------------------------------------"

security dump-keychain "$USER_HOME/Library/Keychains/login.keychain-db" 2>/dev/null \
    | grep -i -E "teams|msteams" \
    | grep -E "svce|acct" \
    | head -50 || true

echo ""
echo "[INFO] Keychain entries were NOT automatically deleted."
echo "[INFO] This prevents accidental removal of unrelated Microsoft credentials."

# ------------------------------------------------------------
# 11. Remove Microsoft Teams launch agents if present
# ------------------------------------------------------------

echo ""
echo "[7/8] Checking Teams launch agents..."

LAUNCH_PATHS=(
    "$USER_HOME/Library/LaunchAgents/com.microsoft.teams.plist"
    "$USER_HOME/Library/LaunchAgents/com.microsoft.teams2.plist"
)

for PATH_ITEM in "${LAUNCH_PATHS[@]}"; do

    if [[ -f "$PATH_ITEM" ]]; then

        echo "[INFO] Found launch agent: $PATH_ITEM"

        launchctl bootout "gui/$(id -u "$CURRENT_USER")" "$PATH_ITEM" 2>/dev/null || true

        remove_path "$PATH_ITEM"

    fi

done

# ------------------------------------------------------------
# 12. Flush relevant caches
# ------------------------------------------------------------

echo ""
echo "[INFO] Flushing user preferences/cache..."

killall cfprefsd 2>/dev/null || true

# ------------------------------------------------------------
# 13. Verification
# ------------------------------------------------------------

echo ""
echo "[8/8] Verifying cleanup..."

echo ""
echo "------------------------------------------------------------"
echo " Application Check"
echo "------------------------------------------------------------"

if [[ ! -d "/Applications/Microsoft Teams.app" ]]; then
    echo "[OK] Microsoft Teams application removed"
else
    echo "[WARN] Microsoft Teams application still exists"
fi

echo ""
echo "------------------------------------------------------------"
echo " Process Check"
echo "------------------------------------------------------------"

if pgrep -if "Microsoft Teams" >/dev/null 2>&1; then
    echo "[WARN] Teams processes are still running"
    pgrep -if "Microsoft Teams" || true
else
    echo "[OK] No Teams processes running"
fi

echo ""
echo "------------------------------------------------------------"
echo " User Data Check"
echo "------------------------------------------------------------"

FOUND=0

for PATH_ITEM in "${USER_PATHS[@]}" "${CONTAINER_PATHS[@]}"; do

    if [[ -e "$PATH_ITEM" ]]; then
        echo "[WARN] Still exists: $PATH_ITEM"
        FOUND=1
    fi

done

if [[ "$FOUND" -eq 0 ]]; then
    echo "[OK] Teams user data removed"
fi

echo ""
echo "============================================================"
echo " Microsoft Teams cleanup completed"
echo "============================================================"
echo ""

echo "Next steps:"
echo ""
echo "1. Restart the Mac"
echo "2. Install the latest Microsoft Teams"
echo "3. Sign in again"
echo ""

read -r -p "Restart the Mac now? [y/N]: " RESTART

if [[ "$RESTART" =~ ^[Yy]$ ]]; then
    echo ""
    echo "[INFO] Restarting..."
    sudo shutdown -r now
else
    echo ""
    echo "[INFO] Restart skipped."
    echo "[INFO] Please restart the Mac before reinstalling Teams."
fi
