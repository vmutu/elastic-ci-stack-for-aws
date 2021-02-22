#!/bin/bash

set -eu -o pipefail

echo "Adding awslogs config..."
sudo mkdir -p /var/awslogs/state
sudo mkdir /etc/awslogs/
sudo cp /tmp/conf/awslogs/awslogs.conf /etc/awslogs/awslogs.conf

echo "Installing awslogs..."
sudo sh -c "curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O"
sudo sh -c "python ./awslogs-agent-setup.py -n --region=us-west-1 --configfile=/etc/awslogs/awslogs.conf"
sudo rm -vf ./awslogs-agent-setup.py

echo "Adding rsyslogd configs..."
sudo cp /tmp/conf/awslogs/rsyslog.d/* /etc/rsyslog.d/
