#!/bin/bash

# Function to check installation status
check_installation() {
    dpkg -l | grep -qw "$1"
}

# Function to print messages
print_message() {
    echo -e "\n\033[1;32m$1\033[0m"
}

# Start installation process
print_message "Starting Kubernetes installation process..."

# Update and install Docker if not installed
if ! check_installation "docker.io"; then
    print_message "Updating system and installing Docker..."
    sudo apt update
    sudo apt install docker.io -y && print_message "Docker installed successfully!" || print_message "Docker installation failed!"
else
    print_message "Docker is already installed, skipping installation."
fi

# Add Kubernetes APT key if not already added
if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
    print_message "Adding Kubernetes APT key..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && print_message "Kubernetes APT key added successfully!" || print_message "Failed to add Kubernetes APT key!"
else
    print_message "Kubernetes APT key is already present, skipping."
fi

# Add Kubernetes APT repository
if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then
    print_message "Adding Kubernetes APT repository..."
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && print_message "Kubernetes APT repository added successfully!" || print_message "Failed to add Kubernetes APT repository!"
else
    print_message "Kubernetes APT repository is already present, skipping."
fi

# Update APT and install Kubernetes components
sudo apt update

for pkg in kubeadm kubelet kubectl; do
    if check_installation "$pkg"; then
        print_message "$pkg is already installed, skipping installation."
    else
        print_message "Installing $pkg..."
        sudo apt install "$pkg" -y && print_message "$pkg installed successfully!" || print_message "Failed to install $pkg!"
    fi
done

# Hold Kubernetes packages
print_message "Holding Kubernetes packages..."
sudo apt-mark hold kubeadm kubelet kubectl && print_message "Packages held successfully!" || print_message "Failed to hold packages!"

# Disable swap
print_message "Disabling swap..."
sudo swapoff -a && print_message "Swap disabled successfully!" || print_message "Failed to disable swap!"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required containerd modules
print_message "Loading required containerd modules..."
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/containerd.conf
sudo modprobe overlay && print_message "Overlay module loaded successfully!" || print_message "Failed to load overlay module!"
sudo modprobe br_netfilter && print_message "Br_netfilter module loaded successfully!" || print_message "Failed to load br_netfilter module!"

# Configure Kubernetes networking
print_message "Configuring Kubernetes networking..."
echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/kubernetes.conf
sudo sysctl --system && print_message "Kubernetes networking configured successfully!" || print_message "Failed to configure Kubernetes networking!"

print_message "Kubernetes installation and configuration complete!"
