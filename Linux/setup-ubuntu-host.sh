#!/bin/bash
# Description: Set the hostname and install an OpenSSH server on Ubuntu
# Platform: Linux

# Funky Setup Script
echo "🎉 Welcome to the Funky Setup Script! 🎉"

# Step 1: Hostname Change
read -p "🤔 What's your new hostname, funky friend? " new_hostname
sudo hostnamectl set-hostname "$new_hostname"
echo "🚀 Your hostname has been changed to: $new_hostname"

# Step 2: Install OpenSSH Server
echo "🔍 Now, let's install the OpenSSH server... Hold tight!"
sudo apt update
if sudo apt install -y openssh-server; then
    echo "🔑 OpenSSH server is now installed! Time to secure those connections!"
else
    echo "❌ Installation failed. Please check your package manager."
    exit 1
fi

# Step 3: Update resolv.conf with cool DNS servers
echo "🌐 Updating resolv.conf with cool DNS servers (8.8.8.8 and 8.8.4.4)!"
{
    echo "# Funky DNS Configuration"
    echo "nameserver 8.8.8.8"
    echo "nameserver 8.8.4.4"
} | sudo tee /etc/resolv.conf > /dev/null
echo "📡 resolv.conf has been updated! Your internet is now groovier!"

# Step 4: Force Reboot the machine
echo "🌀 Time to reboot and let all these changes take effect!"
echo "🚀 Rebooting now... See you on the other side!"
sudo reboot
