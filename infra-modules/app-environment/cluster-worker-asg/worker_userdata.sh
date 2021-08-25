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

# Install yq
sudo wget https://github.com/mikefarah/yq/releases/download/v4.12.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Commands for all K8s nodes
sudo zypper --non-interactive update
sudo zypper --non-interactive install docker

# Turn off swap
# The Kubernetes scheduler determines the best available node on 
# which to deploy newly created pods. If memory swapping is allowed 
# to occur on a host system, this can lead to performance and stability 
# issues within Kubernetes. 
# For this reason, Kubernetes requires that you disable swap in the host system.
# If swap is not disabled, kubelet service will not start on the masters and nodes
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Confirm that docker group has been created on system
sudo groupadd docker

# Add current system user to the Docker group, as well as the ec2-user user
sudo gpasswd -a $USER docker
sudo usermod -a -G docker ec2-user
grep /etc/group -e "docker"

# Start and enable Services
sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

# Modify bridge adapter setting
# Configure sysctl.
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Ensure that the br_netfilter module is loaded
lsmod | grep br_netfilter

# Download cluster yaml file from S3 bucket
aws s3 cp s3://your-rke-cluster-config-bucket/cluster.yml ./

# Get the value of the existing number of nodes listed in the config file and use that
# number for creating a new node listing in the array
aws configure set region eu-west-1
HOSTNAME="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" NUMBER_OF_NODES="$(yq eval '.nodes | length' cluster.yml)" yq eval -i '
  .nodes[env(NUMBER_OF_NODES)].address = env(HOSTNAME) |
  .nodes[env(NUMBER_OF_NODES)].user = "ec2-user" |
  .nodes[env(NUMBER_OF_NODES)].role[0] = "worker"
' ./cluster.yml

# Upload the cluster.yml file to the S3 bucket
aws s3 cp ./cluster.yml s3://your-rke-cluster-config-bucket