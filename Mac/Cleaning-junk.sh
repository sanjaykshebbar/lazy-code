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
        rm -rfv "$1"/*
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

# Function to prompt for password
prompt_for_password() {
    echo -e "${RED}Please enter the password for the admin user '$ADMIN_USER' to continue:${NC}"
    read -s password
}

# Function to run a command as $ADMIN_USER with password prompt
run_as_admin() {
    prompt_for_password
    echo "$password" | sudo -S -u "$ADMIN_USER" "$@"
}

# Check if the script is run as root (required for some operations)
if [ "$(id -u)" -ne "0" ]; then
  echo -e "${RED}This script needs to be run as root (sudo).${NC}"
  exit 1
fi

echo "Starting cleanup..."

# Remove .DS_Store files from the system
echo -n "Removing .DS_Store files..."
run_as_admin find / -name '.DS_Store' -type f -delete
echo -e "${GREEN}Done!${NC}"

# Clean cache files
echo -n "Cleaning cache files..."
run_as_admin safe_rm ~/Library/Logs/
run_as_admin safe_rm ~/System/Library/Caches/
run_as_admin safe_rm ~/Library/Logs/CrashReporter/CoreCapture
run_as_admin safe_rm ~/Library/Logs/CrashReporter
run_as_admin safe_rm ~/Library/Logs/Microsoft/InstallLogs
run_as_admin safe_rm ~/Library/Caches
run_as_admin safe_rm /Library/Caches
run_as_admin safe_rm /System/Library/Caches
run_as_admin safe_rm /Users/$(whoami)/Library/Caches
echo -e "${GREEN}Done!${NC}"

# Restart network services
echo -n "Restarting network services..."
run_as_admin killall -HUP mDNSResponder
echo -e "${GREEN}Done!${NC}"

# Clean system logs and crash reports
echo -n "Cleaning system logs and crash reports..."
run_as_admin safe_rm /var/log
run_as_admin safe_rm ~/Library/Logs
run_as_admin safe_rm /Library/Logs
run_as_admin safe_rm /Library/Logs/DiagnosticReports
echo -e "${GREEN}Done!${NC}"

# Clean temporary files
echo -n "Cleaning temporary files..."
run_as_admin safe_rm /private/var/folders
echo -e "${GREEN}Done!${NC}"

# Empty Trash
echo -n "Removing items from trash..."
run_as_admin safe_rm ~/.Trash
echo -e "${GREEN}Done!${NC}"

# Clean Time Machine snapshots
echo -n "Cleaning Time Machine snapshots..."
run_as_admin tmutil listlocalsnapshots / | grep 'com.apple.TimeMachine' | while read -r snapshot; do
    sudo tmutil deletelocalsnapshots "${snapshot##* }"
done
echo -e "${GREEN}Done!${NC}"

# Update Spotlight index
echo -n "Updating Spotlight index..."
run_as_admin sudo mdutil -E /
echo -e "${GREEN}Done!${NC}"

# Clean Dock data sources
echo -n "Cleaning Dock data sources..."
run_as_admin killall Dock
echo -e "${GREEN}Done!${NC}"

# Clean external drives
clean_external_drives

# Adding a free space check after cleaning
FREE_SPACE=$(df -h / | tail -1 | awk '{print $4}')
echo -e "${GREEN}Free space after cleaning: $FREE_SPACE${NC}"

echo -e "${GREEN}Cleanup completed! All junk files cleared and trash permanently emptied.${NC}"
