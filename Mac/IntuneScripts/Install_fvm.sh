#!/usr/bin/env sh
# lazy-code-stub: true
# =============================================================================
# MOVED - this script now lives at:  Intune/macOS/install-fvm.sh
#
# This stub exists only so previously published curl URLs keep working.
# Please switch to the new URL:
#   curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-fvm.sh | bash
#
# It downloads the real script to a temp file and executes it, so the target's
# own shebang chooses the interpreter (safer than piping into a fixed shell).
# =============================================================================
echo "NOTE: this path has moved to 'Intune/macOS/install-fvm.sh' - forwarding to the new location..." >&2

_tmp="$(mktemp)" || exit 1
if ! curl -fsSL "https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-fvm.sh" -o "$_tmp"; then
    echo "ERROR: could not fetch Intune/macOS/install-fvm.sh" >&2
    rm -f "$_tmp"
    exit 1
fi
chmod +x "$_tmp"
"$_tmp" "$@"
_rc=$?
rm -f "$_tmp"
exit $_rc
