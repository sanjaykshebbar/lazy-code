#!/bin/bash

# Funky Setup Script
echo "🎉 Welcome to the Funky Setup Script! 🎉"

# Step 1: Hostname Change
read -p "🤔 What's your new hostname, funky friend? " new_hostname
sudo hostnamectl set-hostname "$new_hostname"
echo "🚀 Your hostname has been changed to: $new_hostname"

# Step 2: Install OpenSSH Server
echo "🔍 Now, let's install the OpenSSH server... Hold tight!"
sudo apt update && sudo apt install -y openssh-server
echo "🔑 OpenSSH server is now installed! Time to secure those connections!"

# Step 3: Update resolv.conf with cool DNS servers
echo "🌐 Updating resolv.conf with cool DNS servers (8.8.8.8 and 8.8.4.4)!"
sudo bash -c 'cat <<EOL > /etc/resolv.conf
# Funky DNS Configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
EOL'
echo "📡 resolv.conf has been updated! Your internet is now groovier!"

# Step 4: Reboot the machine
echo "🌀 Time to reboot and let all these changes take effect!"
read -p "Are you ready to reboot? (y/n): " ready
if [[ "$ready" == "y" ]]; then
    echo "🚀 Rebooting now... See you on the other side!"
    sudo reboot
else
    echo "😎 No worries! You can reboot later. Just remember to save your work!"
fi
