#!/bin/bash
set -eu -o pipefail

sudo apt-get update -y

echo "Installing ec2-metadata tool ..."
sudo mkdir -p /opt/aws/bin/
sudo wget -O /opt/aws/bin/ec2-metadata http://s3.amazonaws.com/ec2metadata/ec2-metadata
sudo chmod 755 /opt/aws/bin/ec2-metadata

echo "Installing ami tools ..."
sudo apt-get install -y ruby unzip
wget https://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip
sudo unzip ec2-ami-tools.zip -d /opt/aws/
sudo chmod 755 /opt/aws/ec2-ami-tools-*/bin/*
sudo ln -vs /opt/aws/ec2-ami-tools-*/bin/* /opt/aws/bin/
rm -f ec2-ami-tools.zip

echo "Installing cloudformation help scripts ..."
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-1.4-34.zip
sudo unzip aws-cfn-bootstrap-1.4-34.zip -d /opt/aws/
sudo chmod 755 /opt/aws/aws-cfn-bootstrap-*/bin/*
sudo ln -vfs /opt/aws/aws-cfn-bootstrap-*/bin/* /opt/aws/bin/
rm -f aws-cfn-bootstrap-py3-latest.zip

# install cloudformation help scripts deps
sudo sh -c "pip install aws-cfn-bootstrap"
