#!/bin/bash
# Description: Enable Remote Login and advertise the WallpaperWizard MacBook discovery marker.
# Run once in Terminal with sudo. The script contains no credentials.
set -euo pipefail

discovery_marker='WW_MACOS_SHA256_987ead801447509838f013e86c3cefee3ea3a8f02593f3dcf342937ca9071bb1'

step() { printf '\n[%s/4] %s\n' "$1" "$2"; }
fail() { printf '\nSetup stopped. %s\n' "$1" >&2; exit 1; }

configure_discovery_marker() (
  config=/etc/ssh/sshd_config
  [ -f "$config" ] && [ ! -L "$config" ] ||
    fail 'Ask your Mac administrator to add the discovery marker to the active SSH configuration.'

  /usr/bin/ssh-keygen -A || fail 'Could not generate any missing SSH host keys.'
  effective=$(/usr/sbin/sshd -T -f "$config") || fail 'Could not read the active SSH configuration.'
  addendum=$(printf '%s\n' "$effective" | /usr/bin/sed -n 's/^versionaddendum //p')
  case " $addendum " in *" $discovery_marker "*) exit 0 ;; esac

  candidate=$(/usr/bin/mktemp /etc/ssh/.wallpaperwizard-sshd.XXXXXX)
  trap '/bin/rm -f "$candidate"' EXIT
  /bin/cp -p "$config" "$candidate" || fail 'Could not stage the SSH configuration.'
  {
    printf '# WallpaperWizard discovery\nVersionAddendum %s' "$discovery_marker"
    if [ -n "$addendum" ] && [ "$addendum" != none ]; then printf ' %s' "$addendum"; fi
    printf '\n\n'
    /bin/cat "$config"
  } > "$candidate"
  /usr/sbin/sshd -t -f "$candidate" || fail 'SSH rejected the proposed discovery setting. Check the sshd configuration.'
  /bin/mv -f "$candidate" "$config" || fail 'Could not apply the discovery marker.'
)

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

if ! local_uid=$(/usr/bin/dscl /Local/Default -read /Users/ithelpdesk UniqueID 2>/dev/null |
    /usr/bin/awk '$1 == "UniqueID:" { print $2 }'); then
  fail 'WallpaperWizard requires a local account named ithelpdesk. Ask your Mac administrator to configure it.'
fi
if [ -z "$local_uid" ] || [ "$local_uid" = 0 ] || [ "$(/usr/bin/id -u ithelpdesk)" != "$local_uid" ]; then
  fail 'WallpaperWizard requires a local account named ithelpdesk. Ask your Mac administrator to configure it.'
fi
if ! /usr/bin/id -Gn ithelpdesk | /usr/bin/grep -qw admin; then
  fail 'Give the local ithelpdesk account administrator privileges in Users & Groups, then run setup again.'
fi
printf 'Confirmed ithelpdesk is a local administrator.\n'

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
printf 'Remote Login is on. Verify ithelpdesk is allowed under its Sharing settings.\n'

step 3 'Configuring the MacBook discovery marker'
configure_discovery_marker

step 4 'MacBook setup complete'
printf '\nDiscovery marker: %s\n\n' "$discovery_marker"
printf '1. In Push Settings, save the ithelpdesk password and a network range that includes this MacBook.\n'
printf '2. In Devices, select Scan now and approve this MacBook when it appears.\n'
printf '3. Keep a user signed in for a wallpaper push. Allow System Events if macOS prompts.\n'
