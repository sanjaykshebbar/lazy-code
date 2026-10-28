
#!/bin/bash

# ============================================================
# macOS NETWORK DIAGNOSTICS - NOC EDITION
#
# Requirements:
#   - Each ping target runs for 300 seconds
#   - One-second ping interval
#   - All targets run concurrently
#   - Separate logs and start/end timestamps per target
#   - Live terminal dashboard
#   - No administrator credentials required
#
# Run:
#   bash mac_network_diagnostics.sh
# ============================================================

set -u
export LC_ALL=C

PING_DURATION=300
PING_INTERVAL=1
DOWNLOAD_TIMEOUT=15

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_DIR="$HOME/Desktop/MacNetworkDiagnostics_$TIMESTAMP"

mkdir -p "$OUTPUT_DIR" || {
    echo "ERROR: Cannot create output directory: $OUTPUT_DIR"
    exit 1
}

SYSTEM_FILE="$OUTPUT_DIR/SystemInformation.txt"
SUMMARY_FILE="$OUTPUT_DIR/Summary.txt"
PING_INDEX="$OUTPUT_DIR/PingTargets.txt"
DNS_FILE="$OUTPUT_DIR/DNSResults.txt"
SPEED_FILE="$OUTPUT_DIR/DownloadTest.txt"
DASHBOARD_FILE="$OUTPUT_DIR/LiveStatus.txt"

# ------------------------------------------------------------
# Detect Wi-Fi interface
# ------------------------------------------------------------

WIFI_DEV=$(
    networksetup -listallhardwareports 2>/dev/null |
    awk '
        /Hardware Port: Wi-Fi/ || /Hardware Port: AirPort/ {
            getline
            print $2
            exit
        }
    '
)

WIFI_DEV=${WIFI_DEV:-unknown}

# ------------------------------------------------------------
# Detect default route and DNS servers
# ------------------------------------------------------------

GATEWAY=$(route -n get default 2>/dev/null |
    awk '/gateway:/ {print $2; exit}')

ROUTE_INTERFACE=$(route -n get default 2>/dev/null |
    awk '/interface:/ {print $2; exit}')

DNS_SERVERS=$(
    scutil --dns 2>/dev/null |
    awk '/nameserver\[[0-9]+\] :/ {print $3}' |
    awk '!seen[$0]++' |
    head -n 2
)

DNS1=$(printf '%s\n' "$DNS_SERVERS" | sed -n '1p')
DNS2=$(printf '%s\n' "$DNS_SERVERS" | sed -n '2p')

# ------------------------------------------------------------
# Capture initial system information
# ------------------------------------------------------------

{
    echo "MACOS NETWORK DIAGNOSTICS"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Computer: $(scutil --get ComputerName 2>/dev/null || hostname)"
    echo "Hostname: $(hostname)"
    echo "macOS version: $(sw_vers -productVersion)"
    echo "Uptime: $(uptime)"
    echo

    echo "===== NETWORK HARDWARE ====="
    networksetup -listallhardwareports 2>&1

    echo
    echo "===== WIFI NETWORK ====="
    networksetup -getairportnetwork "$WIFI_DEV" 2>&1
    networksetup -getinfo "Wi-Fi" 2>&1

    echo
    echo "===== WIFI INTERFACE DETAILS ====="
    if [ "$WIFI_DEV" != "unknown" ]; then
        ifconfig "$WIFI_DEV" 2>&1
    else
        echo "Wi-Fi interface not detected."
    fi

    echo
    echo "===== DEFAULT ROUTE ====="
    route -n get default 2>&1

    echo
    echo "===== DNS CONFIGURATION ====="
    scutil --dns 2>&1

    echo
    echo "===== WIFI SIGNAL AND CHANNEL INFORMATION ====="
    system_profiler SPAirPortDataType 2>&1

    echo
    echo "===== NETWORK SERVICES ====="
    networksetup -listallnetworkservices 2>&1

    echo
    echo "===== ACTIVE TCP CONNECTIONS ====="
    netstat -an | head -80
} > "$SYSTEM_FILE"

# ------------------------------------------------------------
# Prepare ping target list
# ------------------------------------------------------------

: > "$PING_INDEX"

add_target() {
    LABEL="$1"
    TARGET="$2"

    [ -n "$TARGET" ] || return

    # Avoid testing the same address multiple times.
    if awk -F '|' -v t="$TARGET" '$2 == t {found=1} END {exit !found}' \
        "$PING_INDEX"; then
        return
    fi

    printf '%s|%s\n' "$LABEL" "$TARGET" >> "$PING_INDEX"
}

add_target "Gateway" "$GATEWAY"
add_target "Cloudflare_Public_IP" "1.1.1.1"
add_target "Google_Public_DNS" "8.8.8.8"
add_target "Google_Hostname" "www.google.com"
add_target "Configured_DNS_1" "$DNS1"
add_target "Configured_DNS_2" "$DNS2"

TARGET_COUNT=$(wc -l < "$PING_INDEX" | tr -d ' ')

if [ "$TARGET_COUNT" -eq 0 ]; then
    echo "ERROR: No ping targets available."
    exit 1
fi

# ------------------------------------------------------------
# Continuous ping runner
#
# Each target gets its own 300-second deadline.
# Ping runs at one-second intervals.
# SIGINT is sent at the deadline so ping can print statistics.
# ------------------------------------------------------------

run_continuous_ping() {
    LABEL="$1"
    TARGET="$2"
    LOGFILE="$OUTPUT_DIR/${LABEL}.txt"
    STATUSFILE="$OUTPUT_DIR/.${LABEL}.status"
    STARTFILE="$OUTPUT_DIR/.${LABEL}.start"
    ENDFILE="$OUTPUT_DIR/.${LABEL}.end"

    START_EPOCH=$(date +%s)
    DEADLINE=$((START_EPOCH + PING_DURATION))

    {
        echo "============================================"
        echo "NOC CONTINUOUS PING TEST"
        echo "Target label: $LABEL"
        echo "Target: $TARGET"
        echo "Start time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Required duration: ${PING_DURATION} seconds"
        echo "Ping interval: ${PING_INTERVAL} second"
        echo "============================================"
        echo
    } > "$LOGFILE"

    printf '%s\n' "$START_EPOCH" > "$STARTFILE"
    printf '%s\n' "RUNNING" > "$STATUSFILE"

    case "$TARGET" in
        *:*)
            PING_COMMAND="ping6"
            ;;
        *)
            PING_COMMAND="ping"
            ;;
    esac

    if ! command -v "$PING_COMMAND" >/dev/null 2>&1; then
        echo "ERROR: $PING_COMMAND is unavailable." >> "$LOGFILE"
        printf '%s\n' "ERROR" > "$STATUSFILE"
        date +%s > "$ENDFILE"
        return 1
    fi

    # Launch continuous ping.
    "$PING_COMMAND" -n -i "$PING_INTERVAL" "$TARGET" \
        >> "$LOGFILE" 2>&1 &
    PING_PID=$!

    # Wait until this target's own 300-second deadline.
    while [ "$(date +%s)" -lt "$DEADLINE" ]; do
        if ! kill -0 "$PING_PID" 2>/dev/null; then
            break
        fi
        sleep 0.2
    done

    # Ask ping to terminate gracefully and print its statistics.
    if kill -0 "$PING_PID" 2>/dev/null; then
        kill -INT "$PING_PID" 2>/dev/null || true
    fi

    wait "$PING_PID" 2>/dev/null
    PING_EXIT=$?

    ACTUAL_END=$(date +%s)
    ACTUAL_DURATION=$((ACTUAL_END - START_EPOCH))

    {
        echo
        echo "============================================"
        echo "Test end: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Actual duration: ${ACTUAL_DURATION} seconds"
        echo "Required duration: ${PING_DURATION} seconds"
        echo "Ping process exit code: $PING_EXIT"

        if [ "$ACTUAL_DURATION" -ge "$PING_DURATION" ]; then
            echo "Duration compliance: PASS"
        else
            echo "Duration compliance: REVIEW"
            echo "The ping process exited before its deadline."
        fi

        echo "============================================"
    } >> "$LOGFILE"

    date +%s > "$ENDFILE"

    if [ "$ACTUAL_DURATION" -ge "$PING_DURATION" ]; then
        printf '%s\n' "COMPLETED" > "$STATUSFILE"
    else
        printf '%s\n' "EARLY_EXIT" > "$STATUSFILE"
    fi
}

# ------------------------------------------------------------
# DNS resolution timing test
# ------------------------------------------------------------

run_dns_test() {
    HOST="$1"
    LOGFILE="$2"

    {
        echo "--------------------------------------------"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Hostname: $HOST"

        if command -v dig >/dev/null 2>&1; then
            dig +time=2 +tries=1 "$HOST"
        else
            nslookup "$HOST"
        fi
    } >> "$LOGFILE" 2>&1
}

# ------------------------------------------------------------
# Download throughput test
# ------------------------------------------------------------

run_download_test() {
    {
        echo "Download throughput test"
        echo "Start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Maximum duration: $DOWNLOAD_TIMEOUT seconds"
        echo

        curl -L -o /dev/null -sS \
            --connect-timeout 5 \
            --max-time "$DOWNLOAD_TIMEOUT" \
            -w '\nHTTP status: %{http_code}\nDownload bytes: %{size_download}\nDownload speed: %{speed_download} bytes/sec\nTotal time: %{time_total} seconds\n' \
            'https://speed.cloudflare.com/__down?bytes=10000000'

        echo
        echo "End: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    } > "$SPEED_FILE" 2>&1
}

# ------------------------------------------------------------
# Live dashboard
# ------------------------------------------------------------

show_dashboard() {
    NOW=$(date +%s)
    ELAPSED=$((NOW - MONITOR_START))
    [ "$ELAPSED" -gt "$PING_DURATION" ] && ELAPSED=$PING_DURATION

    FILLED=$((ELAPSED * 30 / PING_DURATION))
    BAR=""

    i=0
    while [ "$i" -lt 30 ]; do
        if [ "$i" -lt "$FILLED" ]; then
            BAR="${BAR}#"
        else
            BAR="${BAR}-"
        fi
        i=$((i + 1))
    done

    REMAINING=$((PING_DURATION - ELAPSED))

    {
        echo "macOS NETWORK DIAGNOSTICS - NOC"
        echo "=============================================="
        echo "Monitoring: $ELAPSED / $PING_DURATION seconds"
        echo "Progress:   [$BAR]"
        echo "Remaining:  $REMAINING seconds"
        echo
        echo "Wi-Fi interface: $WIFI_DEV"
        echo "Default gateway: ${GATEWAY:-Not detected}"
        echo "Route interface: ${ROUTE_INTERFACE:-Unknown}"
        echo
        echo "Concurrent ping targets:"
        while IFS='|' read -r LABEL TARGET; do
            STATUSFILE="$OUTPUT_DIR/.${LABEL}.status"
            STATUS="STARTING"

            if [ -f "$STATUSFILE" ]; then
                STATUS=$(cat "$STATUSFILE")
            fi

            printf "  %-25s %-20s %s\n" "$LABEL" "$TARGET" "$STATUS"
        done < "$PING_INDEX"

        echo
        echo "Latest ping output:"
        for FILE in "$OUTPUT_DIR"/*.txt; do
            [ -f "$FILE" ] || continue
            case "$FILE" in
                */SystemInformation.txt|*/Summary.txt|*/DownloadTest.txt)
                    continue
                    ;;
            esac

            echo
            echo "--- $(basename "$FILE") ---"
            tail -n 3 "$FILE"
        done

        echo
        echo "Report folder:"
        echo "$OUTPUT_DIR"
        echo
        echo "Please keep this Terminal window open."
    } > "$DASHBOARD_FILE"

    printf '\033[2J\033[H'
    cat "$DASHBOARD_FILE"
}

# ------------------------------------------------------------
# Start every ping target concurrently
# ------------------------------------------------------------

echo "Preparing NOC diagnostics..."
echo "Output folder: $OUTPUT_DIR"
echo "Targets detected: $TARGET_COUNT"
echo "Starting all continuous ping processes..."

MONITOR_START=$(date +%s)

while IFS='|' read -r LABEL TARGET; do
    run_continuous_ping "$LABEL" "$TARGET" &
done < "$PING_INDEX"

# ------------------------------------------------------------
# Monitor the full five-minute window
# ------------------------------------------------------------

while [ "$(( $(date +%s) - MONITOR_START ))" -lt "$PING_DURATION" ]; do
    show_dashboard
    sleep 1
done

# Wait for all ping jobs to finish.
# Their individual deadlines begin at their respective launch times.
wait

show_dashboard
echo
echo "All ping jobs have returned. Preparing final report..."

# ------------------------------------------------------------
# Additional DNS checks after the ping monitoring window
# ------------------------------------------------------------

{
    echo "DNS diagnostics"
    echo "Generated: $(date)"
    echo

    run_dns_test "google.com" /dev/stdout
    run_dns_test "apple.com" /dev/stdout

    if [ -n "$DNS1" ]; then
        echo
        echo "Configured DNS server 1: $DNS1"
        dig +time=2 +tries=1 @"$DNS1" google.com
    fi

    if [ -n "$DNS2" ]; then
        echo
        echo "Configured DNS server 2: $DNS2"
        dig +time=2 +tries=1 @"$DNS2" google.com
    fi
} > "$DNS_FILE" 2>&1

# ------------------------------------------------------------
# Download test runs after the continuous ping tests.
# It is deliberately separate from the 300-second ping window.
# ------------------------------------------------------------

run_download_test

# ------------------------------------------------------------
# Generate final summary
# ------------------------------------------------------------

{
    echo "MACOS NETWORK DIAGNOSTICS SUMMARY"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
    echo "Required ping duration per target: $PING_DURATION seconds"
    echo "Ping interval: $PING_INTERVAL second"
    echo "Wi-Fi interface: $WIFI_DEV"
    echo "Default gateway: ${GATEWAY:-Not detected}"
    echo "Route interface: ${ROUTE_INTERFACE:-Unknown}"
    echo
    echo "===== TARGET DURATION COMPLIANCE ====="

    while IFS='|' read -r LABEL TARGET; do
        STARTFILE="$OUTPUT_DIR/.${LABEL}.start"
        ENDFILE="$OUTPUT_DIR/.${LABEL}.end"
        STATUSFILE="$OUTPUT_DIR/.${LABEL}.status"

        if [ -f "$STARTFILE" ] && [ -f "$ENDFILE" ]; then
            S=$(cat "$STARTFILE")
            E=$(cat "$ENDFILE")
            ACTUAL=$((E - S))
            STATUS=$(cat "$STATUSFILE" 2>/dev/null || echo UNKNOWN)

            printf '%s (%s): %s seconds, status=%s\n' \
                "$LABEL" "$TARGET" "$ACTUAL" "$STATUS"
        else
            echo "$LABEL ($TARGET): Missing timestamps"
        fi
    done < "$PING_INDEX"

    echo
    echo "===== PING STATISTICS ====="

    for FILE in "$OUTPUT_DIR"/*.txt; do
        [ -f "$FILE" ] || continue

        case "$FILE" in
            */SystemInformation.txt|*/Summary.txt|*/DownloadTest.txt|*/DNSResults.txt)
                continue
                ;;
        esac

        echo
        echo "--- $(basename "$FILE") ---"

        grep -E \
            'packets transmitted|packets received|packet loss|round-trip|min/avg/max|round-trip min/avg/max|Test end|Actual duration|Duration compliance' \
            "$FILE" || true
    done

    echo
    echo "===== DNS TESTS ====="
    cat "$DNS_FILE"

    echo
    echo "===== DOWNLOAD THROUGHPUT ====="
    cat "$SPEED_FILE"

    echo
    echo "===== INTERPRETATION ====="
    echo "High gateway latency/loss can indicate local Wi-Fi or router trouble."
    echo "Stable gateway but poor public IP connectivity can indicate an ISP issue."
    echo "DNS lookup failures may indicate DNS or general connectivity problems."
    echo "Ping alone does not measure bandwidth."
    echo "ICMP may be blocked by some routers and public destinations."
    echo "Review the default route interface to identify VPN/Ethernet routing."

    echo
    echo "All diagnostic files are in:"
    echo "$OUTPUT_DIR"
} > "$SUMMARY_FILE"

# ------------------------------------------------------------
# Final display
# ------------------------------------------------------------

printf '\033[2J\033[H'

echo "=================================================="
echo " NOC NETWORK DIAGNOSTICS COMPLETED"
echo "=================================================="
echo
echo "Output folder:"
echo "$OUTPUT_DIR"
echo
echo "Summary:"
cat "$SUMMARY_FILE"
echo
echo "Files generated:"
ls -lh "$OUTPUT_DIR"
echo
echo "No administrator credentials were requested."
 
