#!/bin/bash

# This script installs IntelliJ IDEA CE and configures macOS security settings
# Requires admin privileges to install software and change security settings

# Function to run command as the 'ithelpdesk' user using expect for password automation
run_as_ithelpdesk() {
    local password="Gunda@12"
    # Use 'expect' to provide the password interactively for 'sudo' commands
    /usr/bin/expect <<EOF
    spawn sudo -u ithelpdesk $2
    expect "Password:"
    send "$password\r"
    expect eof
EOF
}

# Function to fetch the latest version of IntelliJ IDEA CE
get_latest_version() {
    echo "Fetching the latest version of IntelliJ IDEA CE..."
    
    # Scrape the latest version from the official website
    latest_version=$(curl -s https://www.jetbrains.com/idea/download/ | grep -o 'ideaIC-[0-9]*\.[0-9]*\.[0-9]*' | head -n 1 | sed 's/ideaIC-//')
    
    # Check if the version format is correct
    if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Unable to fetch the latest version. Exiting."
        exit 1
    fi

    echo "Latest version found: $latest_version"
    echo $latest_version
}

# Download IntelliJ IDEA Community Edition from JetBrains
download_intellij() {
    local version=$1
    echo "Downloading IntelliJ IDEA Community Edition version $version..."

    # Construct download URL based on version
    url="https://download.jetbrains.com/idea/ideaIC-${version}.dmg"
    
    # Download the specified version
    curl -L -o ~/Downloads/idea.dmg $url

    # Check if the download was successful
    if [ ! -f ~/Downloads/idea.dmg ]; then
        echo "Error: Failed to download the DMG file."
        exit 1
    fi

    # Optionally, check the file size or verify the download
    # Example: Ensure the file is greater than 100MB (this may vary based on version)
    file_size=$(stat -f %z ~/Downloads/idea.dmg)
    if [ "$file_size" -lt 100000000 ]; then
        echo "Error: The downloaded file seems to be corrupted or incomplete."
        exit 1
    fi
}

# Mount the DMG file
mount_dmg() {
    echo "Mounting the DMG file..."
    hdiutil mount ~/Downloads/idea.dmg
}

# Copy IntelliJ IDEA to the Applications folder
install_app() {
    echo "Installing IntelliJ IDEA..."
    cp -R /Volumes/IntelliJ\ IDEA\ CE/IntelliJ\ IDEA\ CE.app /Applications/
}

# Unmount the DMG
unmount_dmg() {
    echo "Unmounting the DMG..."
    hdiutil unmount /Volumes/IntelliJ\ IDEA\ CE
}

# Configure macOS Security settings (Allow apps from App Store and identified developers)
configure_security() {
    echo "Configuring security settings..."

    # Allow apps from App Store and identified developers (via security command)
    run_as_ithelpdesk "spctl --master-enable"
    run_as_ithelpdesk "spctl --add /Applications/IntelliJ\ IDEA\ CE.app"

    # Allow apps from Unknown Developers as well
    run_as_ithelpdesk "sudo spctl --add /Applications/IntelliJ\ IDEA\ CE.app"
}

# Prompt the user to select the version
prompt_version() {
    echo "Do you want to install a specific version or the latest version?"
    echo "1. Specific Version"
    echo "2. Latest Version"
    read -p "Enter the number (1 or 2): " choice

    if [ "$choice" == "1" ]; then
        read -p "Enter the version number (e.g., 2023.1.4): " version
    elif [ "$choice" == "2" ]; then
        version=$(get_latest_version)
    else
        echo "Invalid choice. Defaulting to latest version."
        version=$(get_latest_version)
    fi

    # Download the selected version
    download_intellij $version
}

# Main installation process
main() {
    # Run the installation process
    prompt_version
    mount_dmg
    install_app
    unmount_dmg
    configure_security

    echo "IntelliJ IDEA CE installation complete!"
}

# Run the installation process
main
