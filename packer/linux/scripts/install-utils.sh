#!/bin/bash
set -eu -o pipefail

echo "Updating core packages"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo chown -R ubuntu:ubuntu /home/ubuntu

echo "Updating awscli..."
sudo apt-get install -y python python-setuptools python-pip 
sudo apt-get install -y python3 python3-setuptools python3-pip
sudo sh -c "pip install --upgrade awscli"
sudo sh -c "pip install future"
sudo sh -c "pip3 install future"

echo "Installing zip utils..."
sudo apt-get install -y zip unzip git pigz

echo "Installing misc utils..."
sudo apt-get install -y libyaml-dev

echo "Installing bk elastic stack bin files..."
sudo chmod +x /tmp/conf/bin/bk-*
sudo mv /tmp/conf/bin/bk-* /usr/local/bin

echo "Configuring awscli to use v4 signatures..."
sudo aws configure set s3.signature_version s3v4

echo "Installing goss for system validation..."
curl -fsSL https://goss.rocks/install | GOSS_VER=v0.3.6 sudo sh
