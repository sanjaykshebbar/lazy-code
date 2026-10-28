#!/bin/bash

# ============================================================
# macOS Network Diagnostics
# Captures system details and performs network ping tests.
# Output: Five diagnostic files in a folder on the user's Desktop.
# Run with:  sh mac_network_diagnostics.sh
#        or:  curl -fsSL <raw-url> | sh
# ============================================================

set -u

PING_COUNT=1300
PING_INTERVAL=1

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_DIR="$HOME/Desktop/MacNetworkDiagnostics_$TIMESTAMP"

if ! mkdir -p "$OUTPUT_DIR"; then
    echo "ERROR: Cannot create output directory."
    exit 1
fi

# ------------------------------------------------------------
# System information
# ------------------------------------------------------------

get_system_info() {
    echo "=================================================="
    echo "macOS Network Diagnostics"
    echo "=================================================="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Computer name: $(scutil --get ComputerName 2>/dev/null || hostname)"
    echo "Local hostname: $(scutil --get LocalHostName 2>/dev/null || hostname)"
    echo "Hostname: $(hostname)"
    echo "Logged-in console user: $(stat -f '%Su' /dev/console 2>/dev/null)"
    echo "Uptime: $(uptime)"
    echo "macOS version: $(sw_vers -productVersion)"
    echo "=================================================="
    echo
}

# ------------------------------------------------------------
# Detect default gateway
# ------------------------------------------------------------

GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}')

# ------------------------------------------------------------
# Detect up to two unique DNS servers
# ------------------------------------------------------------

DNS_TEMP="$OUTPUT_DIR/.dns_servers.tmp"

scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\] :/ {print $3}' \
    | awk '!seen[$0]++' \
    | head -n 2 > "$DNS_TEMP"

DNS1=$(sed -n '1p' "$DNS_TEMP")
DNS2=$(sed -n '2p' "$DNS_TEMP")

rm -f "$DNS_TEMP"

# ------------------------------------------------------------
# Allow manual correction of detected values
# ------------------------------------------------------------

echo "Detected default gateway: ${GATEWAY:-Not detected}"
echo "Detected DNS server 1: ${DNS1:-Not detected}"
echo "Detected DNS server 2: ${DNS2:-Not detected}"
echo

# When run as "curl ... | sh", stdin is the script itself, so prompts
# must read from the terminal (/dev/tty) or they swallow script lines.
ask() {
    # $1 = prompt label, $2 = current value; prints the chosen value
    printf '%s [%s]: ' "$1" "${2:-enter manually}" > /dev/tty
    ANSWER=""
    read -r ANSWER < /dev/tty || ANSWER=""
    if [ -n "$ANSWER" ]; then
        echo "$ANSWER"
    else
        echo "$2"
    fi
}

GATEWAY=$(ask "Gateway IP" "${GATEWAY:-}")
DNS1=$(ask "DNS server 1" "${DNS1:-}")
DNS2=$(ask "DNS server 2" "${DNS2:-}")

# ------------------------------------------------------------
# Save system and network configuration
# ------------------------------------------------------------

{
    get_system_info

    echo "Default gateway: ${GATEWAY:-Not detected}"
    echo "DNS server 1: ${DNS1:-Not detected}"
    echo "DNS server 2: ${DNS2:-Not detected}"
    echo
    echo "Default route:"
    route -n get default 2>&1
    echo
    echo "Network interfaces:"
    networksetup -listallhardwareports 2>&1
    echo
    echo "Configured DNS details:"
    scutil --dns 2>&1
} > "$OUTPUT_DIR/SystemInformation.txt"

# ------------------------------------------------------------
# Run a ping test
# Arguments: target, output file name, description
# Uses ping6 automatically for IPv6 addresses.
# ------------------------------------------------------------

run_ping() {
    local target="$1"
    local output_file="$2"
    local description="$3"
    local ping_cmd="ping"
    local ping_status=0

    case "$target" in
        *:*) ping_cmd="ping6" ;;
    esac

    {
        get_system_info

        echo "Test: $description"
        echo "Target: ${target:-Not detected}"
        echo "Ping interval: $PING_INTERVAL second"
        echo "Packet count: $PING_COUNT"
        echo "Test start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "--------------------------------------------------"

        if [ -z "$target" ]; then
            echo "ERROR: Target not detected. Test skipped."
        else
            "$ping_cmd" -i "$PING_INTERVAL" -c "$PING_COUNT" "$target"
            ping_status=$?

            echo
            echo "Ping exit code: $ping_status"
            echo "0 indicates ping completed without a command-level error."
        fi

        echo "Test end: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
    } >> "$OUTPUT_DIR/$output_file" 2>&1
}

# ------------------------------------------------------------
# Test 1: Google Public DNS
# ------------------------------------------------------------

echo "Starting test 1 of 4..."
run_ping "8.8.8.8" "GoogleDNS.txt" "Google Public DNS"

# ------------------------------------------------------------
# Test 2: Google hostname
# ------------------------------------------------------------

echo "Starting test 2 of 4..."
run_ping "www.google.com" "Google.txt" "Google hostname"

# ------------------------------------------------------------
# Test 3: User DNS servers (both in one file)
# ------------------------------------------------------------

echo "Starting test 3 of 4..."
run_ping "${DNS1:-}" "UsersDNS.txt" "User DNS server 1"
run_ping "${DNS2:-}" "UsersDNS.txt" "User DNS server 2"

# ------------------------------------------------------------
# Test 4: Default gateway
# ------------------------------------------------------------

echo "Starting test 4 of 4..."
run_ping "${GATEWAY:-}" "UsersGateway.txt" "Default gateway"

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

echo
echo "=================================================="
echo "Diagnostics completed."
echo "Results folder: $OUTPUT_DIR"
echo "=================================================="
echo
echo "Generated files:"
ls -lh "$OUTPUT_DIR"
