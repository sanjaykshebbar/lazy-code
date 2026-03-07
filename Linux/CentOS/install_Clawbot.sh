#!/bin/bash

# ==========================================
# Clawbot / OpenClaw Installation Script
# CentOS
# ==========================================

set -e

echo "--------------------------------------"
echo " Updating system packages"
echo "--------------------------------------"

sudo yum update -y

echo "--------------------------------------"
echo " Installing required dependencies"
echo "--------------------------------------"

sudo yum install -y \
git \
python3 \
python3-pip \
python3-devel \
gcc \
gcc-c++ \
make \
curl \
wget

echo "--------------------------------------"
echo " Installing NodeJS (Required for some modules)"
echo "--------------------------------------"

curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

echo "--------------------------------------"
echo " Creating Clawbot directory"
echo "--------------------------------------"

sudo mkdir -p /opt/clawbot
sudo chown $USER:$USER /opt/clawbot

cd /opt/clawbot

echo "--------------------------------------"
echo " Cloning OpenClaw Repository"
echo "--------------------------------------"

git clone https://github.com/openclaw/openclaw.git

cd openclaw

echo "--------------------------------------"
echo " Creating Python virtual environment"
echo "--------------------------------------"

python3 -m venv venv
source venv/bin/activate

echo "--------------------------------------"
echo " Installing Python dependencies"
echo "--------------------------------------"

pip install --upgrade pip
pip install -r requirements.txt

echo "--------------------------------------"
echo " Creating environment configuration"
echo "--------------------------------------"

cp .env.example .env

echo ""
echo "--------------------------------------"
echo " Installation Completed"
echo "--------------------------------------"
echo ""
echo "To start Clawbot:"
echo ""
echo "cd /opt/clawbot/openclaw"
echo "source venv/bin/activate"
echo "python main.py"
echo ""
