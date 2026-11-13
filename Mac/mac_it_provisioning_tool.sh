#!/bin/bash
# macOS IT Provisioning Tool
# Native AppleScript GUI; no Homebrew dependency.
# Run: chmod +x mac_it_provisioning_tool.sh && ./mac_it_provisioning_tool.sh

set -o pipefail
umask 077

APP_TITLE="IT Provisioning Tool"
LOG_DIR="/var/log/ITProvisioning"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="${LOG_DIR}/provisioning_${TIMESTAMP}.log"
WORK_DIR="$(mktemp -d /private/tmp/itprovision.XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

log() {
  local msg="$1"
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $msg" | /usr/bin/tee -a "$LOG_FILE"
}

gui_error() {
  /usr/bin/osascript - "$1" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  display dialog (item 1 of argv) with title "IT Provisioning Tool" buttons {"OK"} default button "OK" with icon stop
end run
APPLESCRIPT
}

gui_info() {
  /usr/bin/osascript - "$1" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  display dialog (item 1 of argv) with title "IT Provisioning Tool" buttons {"OK"} default button "OK" with icon note
end run
APPLESCRIPT
}

gui_text() {
  # Usage: gui_text "Prompt" "Default value"
  /usr/bin/osascript - "$1" "$2" <<'APPLESCRIPT'
on run argv
  set promptText to item 1 of argv
  set defaultText to item 2 of argv
  try
    set resultRecord to display dialog promptText default answer defaultText with title "IT Provisioning Tool" buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel"
    return text returned of resultRecord
  on error number -128
    return "__CANCEL__"
  end try
end run
APPLESCRIPT
}

gui_password() {
  # Password is returned to the calling shell through stdout; never written to the log.
  /usr/bin/osascript - "$1" <<'APPLESCRIPT'
on run argv
  set promptText to item 1 of argv
  try
    set resultRecord to display dialog promptText default answer "" with title "IT Provisioning Tool" buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel" with hidden answer
    return text returned of resultRecord
  on error number -128
    return "__CANCEL__"
  end try
end run
APPLESCRIPT
}

gui_choice() {
  # Usage: gui_choice prompt item1 item2 ...
  /usr/bin/osascript - "$@" <<'APPLESCRIPT'
on run argv
  set promptText to item 1 of argv
  set choiceList to {}
  repeat with i from 2 to count of argv
    set end of choiceList to item i of argv
  end repeat
  try
    set picked to choose from list choiceList with title "IT Provisioning Tool" with prompt promptText OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
    if picked is false then return "__CANCEL__"
    return item 1 of picked
  on error number -128
    return "__CANCEL__"
  end try
end run
APPLESCRIPT
}

gui_multi_choice() {
  # Usage: gui_multi_choice prompt item1 item2 ...
  /usr/bin/osascript - "$@" <<'APPLESCRIPT'
on run argv
  set promptText to item 1 of argv
  set choiceList to {}
  repeat with i from 2 to count of argv
    set end of choiceList to item i of argv
  end repeat
  try
    set picked to choose from list choiceList with title "IT Provisioning Tool" with prompt promptText OK button name "Continue" cancel button name "Cancel" with multiple selections allowed
    if picked is false then return "__CANCEL__"
    if (count of picked) is 0 then return "__NONE__"
    set AppleScript's text item delimiters to "|||"
    set outputText to picked as text
    set AppleScript's text item delimiters to ""
    return outputText
  on error number -128
    return "__CANCEL__"
  end try
end run
APPLESCRIPT
}

choose_installer_file() {
  # Returns selected installer path or "__CANCEL__".
  /usr/bin/osascript <<'APPLESCRIPT'
try
  set f to choose file with prompt "Select the downloaded application installer (.pkg, .mpkg, or .dmg):" of type {"pkg", "mpkg", "dmg", "zip"}
  return POSIX path of f
on error number -128
  return "__CANCEL__"
end try
APPLESCRIPT
}

run_privileged() {
  # The script itself runs as root, so commands do not trigger repeated auth prompts.
  "$@"
}

install_pkg() {
  local pkg="$1"
  log "Installing package: $(/usr/bin/basename "$pkg")"
  if /usr/sbin/installer -pkg "$pkg" -target / >>"$LOG_FILE" 2>&1; then
    log "Package installation completed: $(/usr/bin/basename "$pkg")"
    return 0
  fi
  log "ERROR: Package installation failed: $(/usr/bin/basename "$pkg")"
  return 1
}

install_dmg() {
  local dmg="$1" app_name="$2" mount_point app_path
  mount_point="$WORK_DIR/mount_$(/usr/bin/basename "$dmg" | /usr/bin/tr -cd '[:alnum:]')"
  /bin/mkdir -p "$mount_point"
  log "Mounting DMG: $(/usr/bin/basename "$dmg")"
  if ! /usr/bin/hdiutil attach "$dmg" -nobrowse -quiet -mountpoint "$mount_point" >>"$LOG_FILE" 2>&1; then
    log "ERROR: Could not mount $dmg"
    return 1
  fi

  app_path="$(/usr/bin/find "$mount_point" -maxdepth 3 -type d -name "${app_name}.app" -print -quit 2>/dev/null)"
  if [[ -n "$app_path" ]]; then
    /bin/rm -rf "/Applications/${app_name}.app"
    if /usr/bin/ditto "$app_path" "/Applications/${app_name}.app" >>"$LOG_FILE" 2>&1; then
      log "Copied ${app_name}.app to /Applications"
      /usr/bin/hdiutil detach "$mount_point" -quiet >>"$LOG_FILE" 2>&1 || true
      return 0
    fi
  fi

  /usr/bin/hdiutil detach "$mount_point" -quiet >>"$LOG_FILE" 2>&1 || true
  log "ERROR: ${app_name}.app was not found or could not be copied from DMG"
  return 1
}

install_zip() {
  local archive="$1" app_name="$2" extract_dir app_path
  extract_dir="$WORK_DIR/unzip_$(/usr/bin/basename "$archive" | /usr/bin/tr -cd '[:alnum:]')"
  /bin/mkdir -p "$extract_dir"
  if ! /usr/bin/ditto -x -k "$archive" "$extract_dir" >>"$LOG_FILE" 2>&1; then
    log "ERROR: Could not extract archive: $(/usr/bin/basename "$archive")"
    return 1
  fi
  app_path="$(/usr/bin/find "$extract_dir" -maxdepth 5 -type d -name "${app_name}.app" -print -quit 2>/dev/null)"
  if [[ -z "$app_path" ]]; then
    log "ERROR: ${app_name}.app was not found inside archive"
    return 1
  fi
  /bin/rm -rf "/Applications/${app_name}.app"
  if /usr/bin/ditto "$app_path" "/Applications/${app_name}.app" >>"$LOG_FILE" 2>&1; then
    log "Copied ${app_name}.app from ZIP to /Applications"
    return 0
  fi
  log "ERROR: Could not copy ${app_name}.app from ZIP"
  return 1
}

install_selected_app() {
  local app="$1" page="$2" expected="$3" file rc=0
  if [[ "$app" == "Google Chrome" ]]; then
    local arch url dmg
    arch="$(/usr/bin/uname -m)"
    if [[ "$arch" == "arm64" ]]; then
      url="https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
    else
      url="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
    fi
    dmg="$WORK_DIR/googlechrome.dmg"
    log "Downloading Google Chrome from Google's official download endpoint"
    if /usr/bin/curl -fL --retry 2 --connect-timeout 20 "$url" -o "$dmg" >>"$LOG_FILE" 2>&1; then
      install_dmg "$dmg" "Google Chrome"
      return $?
    fi
    log "ERROR: Chrome download failed"
    return 1
  fi

  gui_info "$app requires a download from its official vendor page. The vendor page will open. Download the macOS installer, return here, and select the downloaded file."
  /usr/bin/open "$page" >/dev/null 2>&1
  file="$(choose_installer_file)"
  if [[ "$file" == "__CANCEL__" ]]; then
    log "Skipped $app: installer selection cancelled"
    return 2
  fi

  case "$file" in
    *.pkg|*.mpkg) install_pkg "$file"; rc=$? ;;
    *.dmg) install_dmg "$file" "$expected"; rc=$? ;;
    *.zip) install_zip "$file" "$expected"; rc=$? ;;
    *) log "ERROR: Unsupported installer file for $app"; rc=1 ;;
  esac
  return "$rc"
}

failures=0
warnings=0

# Basic platform validation.
if [[ "$(/usr/bin/uname -s)" != "Darwin" ]]; then
  gui_error "This tool supports macOS only."
  exit 1
fi

# Elevate once. AppleScript presents the macOS authorization dialog.
if [[ "$(/usr/bin/id -u)" -ne 0 ]]; then
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  /usr/bin/osascript - "$SCRIPT_PATH" <<'APPLESCRIPT'
on run argv
  set scriptPath to item 1 of argv
  do shell script "/bin/bash " & quoted form of scriptPath & " --elevated" with administrator privileges
end run
APPLESCRIPT
  exit $?
fi

if [[ "${1:-}" == "--elevated" ]]; then
  :
fi

/bin/mkdir -p "$LOG_DIR"
 /usr/sbin/chown root:wheel "$LOG_DIR" 2>/dev/null || true
/usr/bin/touch "$LOG_FILE"
/usr/sbin/chown root:wheel "$LOG_FILE" 2>/dev/null || true
/bin/chmod 600 "$LOG_FILE"

log "===== Provisioning started ====="
log "Device: $(/usr/sbin/scutil --get ComputerName 2>/dev/null || /bin/hostname)"
log "macOS: $(/usr/bin/sw_vers -productVersion)"
log "Architecture: $(/usr/bin/uname -m)"

# Organization profile.
ORG="$(gui_choice "Select the organization profile:" "Ryze" "Neo" "Finova" "Custom")"
[[ "$ORG" == "__CANCEL__" ]] && exit 0

# User and device details.
FULL_NAME="$(gui_text "Enter the employee's full name:" "")"
[[ "$FULL_NAME" == "__CANCEL__" || -z "$FULL_NAME" ]] && { gui_error "Employee name is required."; exit 1; }

USER_NAME="$(gui_text "Enter the local username (short name, no spaces):" "")"
[[ "$USER_NAME" == "__CANCEL__" ]] && exit 0
USER_NAME="$(printf '%s' "$USER_NAME" | /usr/bin/tr '[:upper:]' '[:lower:]' | /usr/bin/tr -cd 'a-z0-9._-')"
if [[ -z "$USER_NAME" || "$USER_NAME" == "ithelpdesk" || "$USER_NAME" == "root" ]]; then
  gui_error "Invalid username. Choose a non-empty short name other than ithelpdesk or root."
  exit 1
fi

HOST_NAME="$(gui_text "Enter the hostname / computer name based on designation or role. Use letters, numbers and hyphens only:" "")"
[[ "$HOST_NAME" == "__CANCEL__" || -z "$HOST_NAME" ]] && exit 0
HOST_NAME="$(printf '%s' "$HOST_NAME" | /usr/bin/tr '[:lower:]' '[:upper:]' | /usr/bin/tr -cd 'A-Z0-9-')"
if [[ ! "$HOST_NAME" =~ ^[A-Z0-9][A-Z0-9-]{0,62}$ ]]; then
  gui_error "Invalid hostname. Use 1-63 characters: letters, numbers and hyphens; it must start with a letter or number."
  exit 1
fi

# Account privilege choice. Company defaults can be overridden in the GUI.
DEFAULT_USER_ADMIN="No"
case "$ORG" in
  Ryze|Neo|Finova) DEFAULT_USER_ADMIN="Yes" ;;
  Custom) DEFAULT_USER_ADMIN="No" ;;
esac
USER_ADMIN="$(gui_choice "Should the employee's local account be an administrator? (Profile default: ${DEFAULT_USER_ADMIN})" "Yes" "No")"
[[ "$USER_ADMIN" == "__CANCEL__" ]] && exit 0

# Both account passwords are requested through masked native GUI fields.
HELPDESK_PASSWORD="$(gui_password "Set the password for the local IT Helpdesk administrator account (ithelpdesk):")"
[[ "$HELPDESK_PASSWORD" == "__CANCEL__" || -z "$HELPDESK_PASSWORD" ]] && { gui_error "Helpdesk password cannot be blank."; exit 1; }
HELPDESK_CONFIRM="$(gui_password "Re-enter the IT Helpdesk password to confirm:")"
[[ "$HELPDESK_CONFIRM" == "__CANCEL__" ]] && exit 0
if [[ "$HELPDESK_PASSWORD" != "$HELPDESK_CONFIRM" ]]; then
  unset HELPDESK_PASSWORD HELPDESK_CONFIRM
  gui_error "The IT Helpdesk passwords do not match."
  exit 1
fi
unset HELPDESK_CONFIRM

USER_PASSWORD="$(gui_password "Set the password for employee account '${USER_NAME}':")"
[[ "$USER_PASSWORD" == "__CANCEL__" || -z "$USER_PASSWORD" ]] && { unset HELPDESK_PASSWORD; gui_error "User password cannot be blank."; exit 1; }
USER_CONFIRM="$(gui_password "Re-enter the employee password to confirm:")"
[[ "$USER_CONFIRM" == "__CANCEL__" ]] && { unset HELPDESK_PASSWORD USER_PASSWORD; exit 0; }
if [[ "$USER_PASSWORD" != "$USER_CONFIRM" ]]; then
  unset HELPDESK_PASSWORD USER_PASSWORD USER_CONFIRM
  gui_error "The employee passwords do not match."
  exit 1
fi
unset USER_CONFIRM

# Application selection.
SELECTED_APPS="$(gui_multi_choice "Select applications to install. Chrome can be downloaded automatically; other installers are selected after opening the official vendor page." \
  "DisplayLink Manager" "Google Chrome" "Microsoft Teams" "RustDesk" "Microsoft 365")"
[[ "$SELECTED_APPS" == "__CANCEL__" ]] && { unset HELPDESK_PASSWORD USER_PASSWORD; exit 0; }

# Confirm before making system changes.
SUMMARY="Organization: $ORG
Employee: $FULL_NAME
Username: $USER_NAME
Hostname: $HOST_NAME
IT Helpdesk account: ithelpdesk (administrator)
Employee account administrator: $USER_ADMIN
Applications: ${SELECTED_APPS//|||/, }

Continue with provisioning?"
CONFIRM="$(/usr/bin/osascript - "$SUMMARY" <<'APPLESCRIPT'
on run argv
  try
    set r to display dialog (item 1 of argv) with title "Confirm Provisioning" buttons {"Cancel", "Start Provisioning"} default button "Start Provisioning" cancel button "Cancel" with icon caution
    return "YES"
  on error number -128
    return "NO"
  end try
end run
APPLESCRIPT
)"
if [[ "$CONFIRM" != "YES" ]]; then
  unset HELPDESK_PASSWORD USER_PASSWORD
  log "Provisioning cancelled at confirmation screen"
  exit 0
fi

# Account creation helpers.
create_local_user() {
  local username="$1" fullname="$2" password="$3" make_admin="$4"
  if /usr/bin/dscl . -read "/Users/$username" >/dev/null 2>&1; then
    log "Account $username already exists; updating password and full name"
    /usr/bin/dscl . -change "/Users/$username" RealName "$(/usr/bin/dscl . -read "/Users/$username" RealName 2>/dev/null | /usr/bin/sed 's/^RealName: //')" "$fullname" >/dev/null 2>&1 || \
      /usr/bin/dscl . -create "/Users/$username" RealName "$fullname" >/dev/null 2>&1
    # dscl requires the password as an argument; it is not logged, but may be briefly visible to privileged process inspection.
    /usr/bin/dscl . -passwd "/Users/$username" "$password" >>"$LOG_FILE" 2>&1 || return 1
  else
    local next_uid
    next_uid="$(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/awk '{print $2}' | /usr/bin/sort -n | /usr/bin/awk '$1>=500 && $1<5000 {n=$1} END {print (n<500?n: n+1)}')"
    [[ -z "$next_uid" || "$next_uid" -lt 501 ]] && next_uid=501
    /usr/bin/dscl . -create "/Users/$username" || return 1
    /usr/bin/dscl . -create "/Users/$username" UserShell /bin/zsh || return 1
    /usr/bin/dscl . -create "/Users/$username" RealName "$fullname" || return 1
    /usr/bin/dscl . -create "/Users/$username" UniqueID "$next_uid" || return 1
    /usr/bin/dscl . -create "/Users/$username" PrimaryGroupID 20 || return 1
    /usr/bin/dscl . -create "/Users/$username" NFSHomeDirectory "/Users/$username" || return 1
    /usr/bin/createhomedir -c -u "$username" >/dev/null 2>&1 || return 1
    /usr/bin/dscl . -passwd "/Users/$username" "$password" >>"$LOG_FILE" 2>&1 || return 1
  fi

  if [[ "$make_admin" == "Yes" ]]; then
    /usr/sbin/dseditgroup -o edit -a "$username" -t user admin || return 1
  else
    /usr/sbin/dseditgroup -o edit -d "$username" -t user admin >/dev/null 2>&1 || true
  fi
  return 0
}

log "Creating/updating IT Helpdesk administrator account"
if create_local_user "ithelpdesk" "IT Helpdesk" "$HELPDESK_PASSWORD" "Yes"; then
  log "IT Helpdesk account created/updated and administrator membership verified"
else
  log "ERROR: Failed to create/update IT Helpdesk account"
  failures=$((failures + 1))
fi
unset HELPDESK_PASSWORD

log "Creating/updating employee account: $USER_NAME"
if create_local_user "$USER_NAME" "$FULL_NAME" "$USER_PASSWORD" "$USER_ADMIN"; then
  log "Employee account created/updated"
else
  log "ERROR: Failed to create/update employee account"
  failures=$((failures + 1))
fi
unset USER_PASSWORD

# Set all three macOS computer naming values.
log "Setting ComputerName, LocalHostName and HostName to $HOST_NAME"
for name_key in ComputerName LocalHostName HostName; do
  if /usr/sbin/scutil --set "$name_key" "$HOST_NAME" >>"$LOG_FILE" 2>&1; then
    log "$name_key updated"
  else
    log "ERROR: Could not update $name_key"
    failures=$((failures + 1))
  fi
done

# Install selected applications.
IFS='|||' read -r -a APP_ARRAY <<< "$SELECTED_APPS"
for app in "${APP_ARRAY[@]}"; do
  case "$app" in
    "DisplayLink Manager")
      install_selected_app "$app" "https://www.synaptics.com/products/displaylink-graphics/downloads/macos" "DisplayLink Manager"
      rc=$?
      ;;
    "Google Chrome")
      install_selected_app "$app" "" "Google Chrome"
      rc=$?
      ;;
    "Microsoft Teams")
      install_selected_app "$app" "https://www.microsoft.com/en-us/microsoft-teams/download-app" "Microsoft Teams"
      rc=$?
      ;;
    "RustDesk")
      install_selected_app "$app" "https://rustdesk.com/download/" "RustDesk"
      rc=$?
      ;;
    "Microsoft 365")
      install_selected_app "$app" "https://m365.cloud.microsoft/apps" "Microsoft 365"
      rc=$?
      ;;
    *) continue ;;
  esac
  if [[ "$rc" -eq 1 ]]; then
    failures=$((failures + 1))
  elif [[ "$rc" -eq 2 ]]; then
    warnings=$((warnings + 1))
  fi
done

# Post-provisioning checks.
log "===== Verification ====="
for account in ithelpdesk "$USER_NAME"; do
  if /usr/bin/dscl . -read "/Users/$account" UniqueID >/dev/null 2>&1; then
    log "PASS: Local account exists: $account"
  else
    log "FAIL: Local account missing: $account"
    failures=$((failures + 1))
  fi
done

if /usr/sbin/dseditgroup -o checkmember -m ithelpdesk admin 2>&1 | /usr/bin/grep -q "yes"; then
  log "PASS: ithelpdesk is an administrator"
else
  log "FAIL: ithelpdesk admin membership not verified"
  failures=$((failures + 1))
fi

if [[ "$USER_ADMIN" == "Yes" ]]; then
  if /usr/sbin/dseditgroup -o checkmember -m "$USER_NAME" admin 2>&1 | /usr/bin/grep -q "yes"; then
    log "PASS: $USER_NAME is an administrator"
  else
    log "FAIL: $USER_NAME admin membership not verified"
    failures=$((failures + 1))
  fi
else
  log "INFO: $USER_NAME configured as standard user"
fi

for name_key in ComputerName LocalHostName HostName; do
  current="$(/usr/sbin/scutil --get "$name_key" 2>/dev/null || true)"
  if [[ "$current" == "$HOST_NAME" ]]; then
    log "PASS: $name_key = $current"
  else
    log "FAIL: $name_key is '$current', expected '$HOST_NAME'"
    failures=$((failures + 1))
  fi
done

log "Provisioning completed. Failures: $failures; skipped installers: $warnings"
RESULT="Provisioning completed.

Failures: $failures
Skipped/cancelled installer steps: $warnings

Log file:
$LOG_FILE

Next steps:
1. Sign in to Microsoft 365 with the employee's work account.
2. Complete OneDrive sign-in and enable folder sync.
3. Approve DisplayLink screen-recording permission if prompted.
4. Approve RustDesk Accessibility and Screen Recording permissions if required.
5. Restart the Mac if DisplayLink or hostname changes require it."

if [[ "$failures" -eq 0 ]]; then
  gui_info "$RESULT"
else
  gui_error "$RESULT"
fi

log "===== Provisioning finished ====="
exit 0
