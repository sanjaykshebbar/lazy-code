
#!/bin/bash

# macOS Network Diagnostics
# Captures system information in every output file.
# Tests Google DNS, Google hostname, both user DNS servers,
# and the default gateway.

set -u

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_DIR="$HOME/Desktop/MacNetworkDiagnostics_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR" || exit 1

get_system_info() {
    echo "=================================================="
    echo "macOS Network Diagnostics"
    echo "=================================================="
    echo "Diagnostic timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Computer name: $(scutil --get ComputerName 2>/dev/null || hostname)"
    echo "Local hostname: $(scutil --get LocalHostName 2>/dev/null || hostname)"
    echo "Hostname: $(hostname)"
    echo "Logged-in console user: $(stat -f '%Su' /dev/console 2>/dev/null)"
    echo "Uptime: $(uptime)"
    echo "=================================================="
    echo
}

# Detect the default gateway
GATEWAY=$(route -n get default 2>/dev/null |
    awk '/gateway:/ {print $2; exit}')

# Detect up to two unique configured DNS server addresses
DNS_SERVERS=()
while IFS= read -r server; do
    [[ -n "$server" ]] && DNS_SERVERS+=("$server")
done < <(
    scutil --dns 2>/dev/null |
    awk '/nameserver\[[0-9]+\] :/ {print $3}' |
    awk '!seen[$0]++' |
    head -n 2
)

# Allow manual correction if automatic detection is incorrect
echo "Detected gateway: ${GATEWAY:-Not detected}"
echo "Detected DNS servers:"
for i in "${!DNS_SERVERS[@]}"; do
    echo "DNS $((i + 1)): ${DNS_SERVERS[$i]}"
done

read -r -p "Override gateway (press Enter to accept detected value): " GW_INPUT
[[ -n "$GW_INPUT" ]] && GATEWAY="$GW_INPUT"

for i in 0 1; do
    current="${DNS_SERVERS[$i]:-}"
    read -r -p "DNS $((i + 1)) [$current]: " DNS_INPUT
    if [[ -n "$DNS_INPUT" ]]; then
        DNS_SERVERS[$i]="$DNS_INPUT"
    fi
done

# Write a shared system-information file
{
    get_system_info
    echo "Default gateway: ${GATEWAY:-Not detected}"
    echo "DNS server 1: ${DNS_SERVERS[0]:-Not detected}"
    echo "DNS server 2: ${DNS_SERVERS[1]:-Not detected}"
    echo
    echo "Default route:"
    route -n get default 2>&1
    echo
    echo "Configured DNS details:"
    scutil --dns 2>&1
} > "$OUTPUT_DIR/SystemInformation.txt"

# Every output file starts with the system details
write_header() {
    get_system_info
    echo "Test: $1"
    echo "Target: $2"
    echo "Ping interval: 1 second"
    echo "Packets per target: 1300"
    echo "--------------------------------------------------"
}

run_ping() {
    local target="$1"
    local output_file="$2"
    local description="$3"

    if [[ -z "$target" ]]; then
        {
            write_header "$description" "Not detected"
            echo "ERROR: No target available; test skipped."
        } >> "$OUTPUT_DIR/$output_file"
        return
    fi

    echo "Running $description: $target"

    {
        write_header "$description" "$target"
        ping -i 1 -c 1300 "$target"
        rc=$?
        echo
        echo "Ping exit code: $rc"
        echo "Test end time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
    } >> "$OUTPUT_DIR/$output_file" 2>&1
}

# Test 1: Google public DNS
run_ping "8.8.8.8" "GoogleDNS.txt" "Google Public DNS"

# Test 2: Google hostname
run_ping "www.google.com" "Google.txt" "Google hostname"

# Test 3: Both user DNS servers in one file
for i in "${!DNS_SERVERS[@]}"; do
    run_ping "${DNS_SERVERS[$i]}" "UsersDNS.txt" \
        "User DNS server $((i + 1))"
done

if [[ ${#DNS_SERVERS[@]} -eq 0 ]]; then
    run_ping "" "UsersDNS.txt" "User DNS servers"
fi

# Test 4: Default gateway
run_ping "${GATEWAY:-}" "UsersGateway.txt" "Default gateway"

echo
echo "Diagnostics completed."
echo "Output folder: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
