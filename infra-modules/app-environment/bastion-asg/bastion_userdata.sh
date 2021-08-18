#!/bin/bash

# Install utils and aws cli v2
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get update
sudo apt-get -y install jq
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
sudo apt-get install zip
sudo apt-get install unzip
sudo unzip awscliv2.zip
sudo ./aws/install

# Download and install kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

sleep 4m 30s

# Download cluster config file and ssh key from S3 bucket
aws s3 cp s3://euw1-rke-cluster-config/cluster.yml ./
aws s3 cp s3://euw1-rke-cluster-config/your-rke.pem ./
chmod 400 ./your-rke.pem

# Download RKE
curl -LO https://github.com/rancher/rke/releases/download/v1.2.11/rke_linux-amd64 && chmod a+x ./rke_linux-amd64
mv rke_linux-amd64 rke

# Provision RKE cluster
./rke up --config ./cluster.yml

# Copy details of cluster config to Secrets Manager
# Store Kube Config as secret for worker nodes
KUBE_CONFIG=$(cat kube_config_cluster.yml)
aws secretsmanager create-secret --name rkekubeconfig --description "Kube config for RKE cluster" --secret-string "$KUBE_CONFIG" --region eu-west-1

