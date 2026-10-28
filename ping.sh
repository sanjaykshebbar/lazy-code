
#!/bin/bash

# ============================================================
# macOS Network Diagnostics
# Captures system details and performs network ping tests.
# Output: Five diagnostic files on the user's Desktop.
# ============================================================

set -u

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

GATEWAY=$(route -n get default 2>/dev/null |
    awk '/gateway:/ {print $2; exit}')

# ------------------------------------------------------------
# Detect up to two unique DNS servers
# Use a regular temporary file rather than process substitution.
# This avoids the syntax error encountered with sh.
# ------------------------------------------------------------

DNS_TEMP="$OUTPUT_DIR/.dns_servers.tmp"

scutil --dns 2>/dev/null |
    awk '/nameserver\[[0-9]+\] :/ {print $3}' |
    awk '!seen[$0]++' |
    head -n 2 > "$DNS_TEMP"

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

read -r -p "Gateway IP [${GATEWAY:-enter manually}]: " INPUT
if [[ -n "$INPUT" ]]; then
    GATEWAY="$INPUT"
fi

read -r -p "DNS server 1 [${DNS1:-enter manually}]: " INPUT
if [[ -n "$INPUT" ]]; then
    DNS1="$INPUT"
fi

read -r -p "DNS server 2 [${DNS2:-enter manually}]: " INPUT
if [[ -n "$INPUT" ]]; then
    DNS2="$INPUT"
fi

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
# -i 1 = approximately one-second interval
# -c 1300 = send 1300 packets and stop
# ------------------------------------------------------------

run_ping() {
    TARGET="$1"
    OUTPUT_FILE="$2"
    DESCRIPTION="$3"

    {
        get_system_info

        echo "Test: $DESCRIPTION"
        echo "Target: ${TARGET:-Not detected}"
        echo "Ping interval: 1 second"
        echo "Packet count: 1300"
        echo "Test start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "--------------------------------------------------"

        if [[ -z "$TARGET" ]]; then
            echo "ERROR: Target not detected. Test skipped."
        else
            ping -i 1 -c 1300 "$TARGET"
            PING_STATUS=$?

            echo
            echo "Ping exit code: $PING_STATUS"
            echo "0 indicates ping completed without a command-level error."
        fi

        echo "Test end: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
    } >> "$OUTPUT_DIR/$OUTPUT_FILE" 2>&1
}

# ------------------------------------------------------------
# Test 1: Google Public DNS
# ------------------------------------------------------------

echo "Starting test 1 of 5..."
run_ping "8.8.8.8" "GoogleDNS.txt" "Google Public DNS"

# ------------------------------------------------------------
# Test 2: Google hostname
# ------------------------------------------------------------

echo "Starting test 2 of 5..."
run_ping "www.google.com" "Google.txt" "Google hostname"

# ------------------------------------------------------------
# Test 3: User DNS servers (both in one file)
# ------------------------------------------------------------

echo "Starting test 3 of 5..."

if [[ -n "$DNS1" ]]; then
    run_ping "$DNS1" "UsersDNS.txt" "User DNS server 1"
else
    run_ping "" "UsersDNS.txt" "User DNS server 1"
fi

if [[ -n "$DNS2" ]]; then
    run_ping "$DNS2" "UsersDNS.txt" "User DNS server 2"
else
    run_ping "" "UsersDNS.txt" "User DNS server 2"
fi

# ------------------------------------------------------------
# Test 4: Default gateway
# ------------------------------------------------------------

echo "Starting test 4 of 5..."
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
