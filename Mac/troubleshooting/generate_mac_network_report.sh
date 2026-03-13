#!/bin/bash

# ================================
# macOS Network Usage Report Tool
# ================================

set -e

WORKDIR="$HOME/mac_network_report"
COLLECTOR_URL="https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/Mac/troubleshooting/network_usage_collector.sh"
REPORT_URL="https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/Mac/troubleshooting/generate_report.py"

echo "Creating working directory..."

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading latest scripts from GitHub..."

curl -s -O "$COLLECTOR_URL"
curl -s -O "$REPORT_URL"

chmod +x network_usage_collector.sh

echo ""
echo "-------------------------------------"
echo "Step 1: Collecting network statistics"
echo "-------------------------------------"

sudo ./network_usage_collector.sh

echo ""
echo "Validating output..."

if [ ! -f network_usage.json ]; then
    echo "ERROR: network_usage.json not generated"
    exit 1
fi

echo ""
echo "-------------------------------------"
echo "Step 2: Generating HTML report"
echo "-------------------------------------"

python3 generate_report.py

if [ ! -f network_report.html ]; then
    echo "ERROR: HTML report not generated"
    exit 1
fi

echo ""
echo "-------------------------------------"
echo "Report generated successfully"
echo "-------------------------------------"

echo "Location:"
echo "$WORKDIR/network_report.html"

echo ""
echo "Opening report in browser..."

open network_report.html
