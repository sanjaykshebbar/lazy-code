#!/bin/bash
# Description: Enable Remote Login and print the SSH fingerprint used to enroll a MacBook in WallpaperWizard.
# Run once in Terminal with sudo. The script contains no credentials.
set -euo pipefail

step() { printf '\n[%s/4] %s\n' "$1" "$2"; }
fail() { printf '\nSetup stopped. %s\n' "$1" >&2; exit 1; }

printf 'WallpaperWizard MacBook setup\n'
printf 'This prepares the MacBook for wallpaper management over SSH.\n'

step 1 'Checking macOS, hardware model, and administrator access'
[ "$(uname -s)" = Darwin ] || fail 'Run this script in Terminal on the MacBook you want to enroll.'
[ "$(id -u)" -eq 0 ] || fail 'Run the setup command with sudo, as shown in Push Settings.'

if ! model=$(/usr/sbin/system_profiler SPHardwareDataType -xml | /usr/bin/xmllint --nonet \
    --xpath 'string((//key[.="machine_name"]/following-sibling::string[1])[1])' -); then
  fail 'Could not read the hardware model. Verify the Mac model in Apple menu > About This Mac.'
fi
case "$model" in
  MacBook|MacBook\ *) printf 'Detected %s.\n' "$model" ;;
  *) fail "WallpaperWizard enrolls MacBook models. Detected model: ${model:-unknown}." ;;
esac

step 2 'Enabling Remote Login'
if ! LC_ALL=C /usr/sbin/systemsetup -getremotelogin | /usr/bin/grep -Eq ':[[:space:]]*On[[:space:]]*$'; then
  remote_login_message=$(LC_ALL=C /usr/sbin/systemsetup -setremotelogin on 2>&1) || true
  if ! LC_ALL=C /usr/sbin/systemsetup -getremotelogin | /usr/bin/grep -Eq ':[[:space:]]*On[[:space:]]*$'; then
    if [ -n "$remote_login_message" ]; then
      printf '%s\n' "$remote_login_message" >&2
    fi
    case "$remote_login_message" in
      *'Full Disk Access'*)
        printf '%s\n' \
          'macOS requires an administrator to approve Full Disk Access for Terminal.' \
          'Open Full Disk Access manually from System Settings > Privacy & Security if needed.' \
          'Enable Terminal, authenticate when prompted, then quit and reopen Terminal before running setup again.' \
          'You can also turn on Remote Login directly in Sharing settings and rerun setup with the current Terminal permissions.' >&2
        if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_UID:-0}" -ne 0 ]; then
          case "$(/usr/bin/sw_vers -productVersion)" in
            10.*|11.*|12.*)
              settings_url='x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'
              ;;
            *)
              settings_url='x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles'
              ;;
          esac
          /bin/launchctl asuser "$SUDO_UID" /usr/bin/sudo -u "$SUDO_USER" -- /usr/bin/open "$settings_url" ||
            printf '%s\n' 'Could not open the Settings window. Open Full Disk Access manually.' >&2
        fi
        ;;
    esac
    fail 'Turn on Remote Login in System Settings > General > Sharing, allow your device administrator account, then run setup again.'
  fi
fi
printf 'Remote Login is on. Verify your device administrator is allowed under its Sharing settings.\n'

step 3 'Reading this MacBook’s public SSH host fingerprint'
key=/etc/ssh/ssh_host_ed25519_key.pub
if [ ! -r "$key" ]; then
  /usr/bin/ssh-keygen -A || fail 'SSH host key generation failed.'
fi
fingerprint=$(/usr/bin/ssh-keygen -E sha256 -lf "$key" | /usr/bin/awk '{print $2}') ||
  fail 'Could not read the Ed25519 SSH host fingerprint.'
case "$fingerprint" in
  SHA256:*) ;;
  *) fail 'Could not read the Ed25519 SSH host fingerprint.' ;;
esac

step 4 'Ready to enroll this MacBook'
printf '\n%s\n\n' "$fingerprint"
printf '1. In Dashboard > Push Settings, paste the SHA256 value into MacBook fingerprints.\n'
printf '2. Add this MacBook address or its network range and save your settings.\n'
printf '3. In Dashboard > Devices, select Scan now and approve the MacBook if it is pending.\n'
printf '4. Keep a user signed in for a wallpaper push. Allow System Events if macOS prompts.\n'
