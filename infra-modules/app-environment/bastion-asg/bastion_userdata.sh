#!/bin/bash

# Install utils and aws cli v2
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo zypper --non-interactive update
sudo zypper --non-interactive install jq
sudo zypper --non-interactive update
sudo zypper --non-interactive install zip
sudo zypper --non-interactive install unzip
sudo unzip awscliv2.zip
sudo ./aws/install

sleep 4m 30s

# Download cluster config file and ssh key from S3 bucket
aws s3 cp s3://your-rke-cluster-config-bucket/cluster.yml ./
aws s3 cp s3://your-rke-cluster-config-bucket/ec2-ssh-key.pem ./
chmod 400 ./ec2-ssh-key.pem

# Download RKE
curl -LO https://github.com/rancher/rke/releases/download/v1.2.11/rke_linux-amd64 && chmod a+x ./rke_linux-amd64
mv rke_linux-amd64 rke

# Provision RKE cluster
./rke up --config ./cluster.yml

# Copy details of cluster config to Secrets Manager
# Store Kube Config as secret for worker nodes
KUBE_CONFIG=$(cat kube_config_cluster.yml)
aws secretsmanager create-secret --name rkekubeconfig --description "Kube config for RKE cluster" --secret-string "$KUBE_CONFIG" --region eu-west-1

# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client