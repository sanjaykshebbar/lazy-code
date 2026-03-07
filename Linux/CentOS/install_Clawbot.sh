#!/bin/bash

# =====================================================
# Clawbot / OpenClaw Full Auto Installer
# CentOS / RHEL / Rocky / Alma
# Author: Sanjay KS
# =====================================================

set -e

INSTALL_DIR="/opt/clawbot"
REPO_URL="https://github.com/openclaw/openclaw.git"
SERVICE_NAME="clawbot"

echo "========================================"
echo " Clawbot Automated Installation"
echo "========================================"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with sudo"
  exit
fi

echo ""
echo "Updating system..."
yum update -y

echo ""
echo "Installing dependencies..."

yum install -y \
git \
python3 \
python3-pip \
python3-devel \
gcc \
gcc-c++ \
make \
curl \
wget \
epel-release

echo ""
echo "Installing NodeJS..."

curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

echo ""
echo "Creating installation directory..."

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

if [ -d "$INSTALL_DIR/openclaw" ]; then
    echo "Existing installation detected. Removing..."
    rm -rf $INSTALL_DIR/openclaw
fi

echo ""
echo "Cloning OpenClaw repository..."

git clone $REPO_URL
cd openclaw

echo ""
echo "Setting up Python virtual environment..."

python3 -m venv venv
source venv/bin/activate

echo ""
echo "Installing Python dependencies..."

pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Configuring environment file..."

if [ -f ".env.example" ]; then
    cp .env.example .env
fi

echo ""
echo "Creating systemd service..."

cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Clawbot AI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/openclaw
ExecStart=$INSTALL_DIR/openclaw/venv/bin/python main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Reloading systemd..."

systemctl daemon-reload

echo ""
echo "Enabling service..."

systemctl enable $SERVICE_NAME

echo ""
echo "Starting Clawbot service..."

systemctl start $SERVICE_NAME

echo ""
echo "========================================"
echo " Installation Completed"
echo "========================================"
echo ""
echo "Service Status:"
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "Commands:"
echo "Start   : sudo systemctl start $SERVICE_NAME"
echo "Stop    : sudo systemctl stop $SERVICE_NAME"
echo "Restart : sudo systemctl restart $SERVICE_NAME"
echo "Logs    : sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "Installation Path:"
echo "$INSTALL_DIR/openclaw"
