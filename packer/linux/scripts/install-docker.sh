#!/bin/bash
set -eu -o pipefail

# add docker repo
sudo wget -q -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'
sudo apt-get -y update

# remove if already installed
sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose

# install docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# install docker-compose
sudo apt-get install -y libffi-dev libssl1.1 libssl-dev python3-dev
CONSTRAINT_FILE="/tmp/docker-compose-pip-constraint"
echo 'cryptography<3.4' >"$CONSTRAINT_FILE"
sudo pip3 install --constraint "$CONSTRAINT_FILE" docker-compose
docker-compose version

# add user ubuntu to docker group
sudo usermod -a -G docker ubuntu

# install jq
sudo apt-get install -y jq
