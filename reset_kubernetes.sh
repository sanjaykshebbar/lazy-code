#!/bin/bash

# Function to reset Kubernetes cluster
reset_kubernetes() {
    echo "Resetting Kubernetes cluster..."
    sudo kubeadm reset -f

    if [ $? -ne 0 ]; then
        echo "Failed to reset Kubernetes cluster."
        exit 1
    fi
    echo "Kubernetes cluster reset successfully."
}

# Function to remove residual files
remove_residual_files() {
    echo "Removing residual files..."
    sudo rm -rf ~/.kube
    sudo rm -rf /etc/kubernetes
    sudo rm -rf /var/lib/etcd
    sudo rm -rf /var/lib/kubelet/*
    sudo rm -rf /var/run/kubernetes
    sudo rm -rf /etc/cni/net.d
    sudo rm -rf /opt/cni/bin

    # If you used any network plugin, you might want to remove its configurations as well
    # Example: Calico, Flannel, etc.
    # sudo rm -rf /etc/cni/net.d/<network-plugin-config>

    echo "Residual files removed successfully."
}

# Function to clean up Docker
clean_docker() {
    echo "Cleaning up Docker images and containers..."
    sudo docker system prune -af

    if [ $? -ne 0 ]; then
        echo "Failed to clean up Docker."
        exit 1
    fi
    echo "Docker cleaned up successfully."
}

# Main script execution
reset_kubernetes
remove_residual_files
clean_docker

echo "Kubernetes and residual files have been successfully reset."
