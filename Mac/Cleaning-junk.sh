#!/bin/bash

# Defining colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Default admin user
ADMIN_USER="ithelpdesk"

# Function to check if the directory exists before attempting to clean it
safe_rm() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}Cleaning $1...${NC}"
        sudo rm -rfv "$1"/*
    else
        echo -e "${RED}Directory $1 does not exist and will be ignored.${NC}"
    fi
}

# Function to clean external drives
clean_external_drives() {
    echo -e "${GREEN}Cleaning external drives...${NC}"
    for disk in $(diskutil list | grep 'external' | awk '{print $NF}'); do
        mount_point=$(diskutil info "$disk" | grep 'Mount Point' | awk -F': ' '{print $2}')
        if [ "$mount_point" != "Not mounted" ] && [ -n "$mount_point" ]; then
            echo -e "${GREEN}Cleaning $mount_point...${NC}"
            safe_rm "$mount_point"
        else
            echo -e "${RED}$disk is not mounted or mount point not found.${NC}"
        fi
    done
}

# Function to calculate elapsed time in minutes and seconds
elapsed_time() {
    local SECONDS=$(($SECONDS - $START_TIME))
    local MINUTES=$((SECONDS / 60))
    local REMAINING_SECONDS=$((SECONDS % 60))
    echo -e "${GREEN}Elapsed time: ${MINUTES}m ${REMAINING_SECONDS}s${NC}"
}

# Check if the script is run as root (required for some operations)
if [ "$(id -u)" -ne "0" ]; then
  echo -e "${RED}This script needs to be run as root (sudo).${NC}"
  exit 1
fi

# Start the timer
START_TIME=$SECONDS

echo "Starting cleanup..."

# Remove .DS_Store files from the system
echo -n "Removing .DS_Store files..."
sudo find / -name '.DS_Store' -type f -delete
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean cache files
echo -n "Cleaning cache files..."
safe_rm ~/Library/Logs/
safe_rm ~/System/Library/Caches/
safe_rm ~/Library/Logs/CrashReporter/CoreCapture
safe_rm ~/Library/Logs/CrashReporter
safe_rm ~/Library/Logs/Microsoft/InstallLogs
safe_rm ~/Library/Caches
safe_rm /Library/Caches
safe_rm /System/Library/Caches
safe_rm /Users/$(whoami)/Library/Caches
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Restart network services
echo -n "Restarting network services..."
sudo killall -HUP mDNSResponder
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean system logs and crash reports
echo -n "Cleaning system logs and crash reports..."
safe_rm /var/log
safe_rm ~/Library/Logs
safe_rm /Library/Logs
safe_rm /Library/Logs/DiagnosticReports
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean temporary files
echo -n "Cleaning temporary files..."
safe_rm /private/var/folders
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Empty Trash
echo -n "Removing items from trash..."
safe_rm ~/.Trash
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean Time Machine snapshots
echo -n "Cleaning Time Machine snapshots..."
sudo tmutil listlocalsnapshots / | grep 'com.apple.TimeMachine' | while read -r snapshot; do
    sudo tmutil deletelocalsnapshots "${snapshot##* }"
done
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Update Spotlight index
echo -n "Updating Spotlight index..."
sudo mdutil -E /
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean Dock data sources
echo -n "Cleaning Dock data sources..."
sudo killall Dock
elapsed_time
echo -e "${GREEN}Done!${NC}"

# Clean external drives
clean_external_drives

# Adding a free space check after cleaning
FREE_SPACE=$(df -h / | tail -1 | awk '{print $4}')
elapsed_time
echo -e "${GREEN}Free space after cleaning: $FREE_SPACE${NC}"

echo -e "${GREEN}Cleanup completed! All junk files cleared and trash permanently emptied.${NC}"
