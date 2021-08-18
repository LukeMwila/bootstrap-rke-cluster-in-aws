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

# Commands for all K8s nodes
# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Add Docker Repo
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update Packages
sudo apt-get update

# Turn off swap
# The Kubernetes scheduler determines the best available node on 
# which to deploy newly created pods. If memory swapping is allowed 
# to occur on a host system, this can lead to performance and stability 
# issues within Kubernetes. 
# For this reason, Kubernetes requires that you disable swap in the host system.
# If swap is not disabled, kubelet service will not start on the masters and nodes
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

sudo apt install -y containerd.io docker-ce=5:19.03.9~3-0~ubuntu-focal docker-ce-cli=5:19.03.9~3-0~ubuntu-focal

# Create required directories
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create daemon json config file
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Confirm that docker group has been created on system
sudo groupadd docker

# Add your current system user to the Docker group, as well as the ubuntu user
sudo gpasswd -a $USER docker
sudo usermod -a -G docker ubuntu
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
aws s3 cp s3://euw1-rke-cluster-config/cluster.yml ./

# Get the value of the existing number of nodes listed in the config file and use that
# number for creating a new node listing in the array
HOSTNAME="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" NUMBER_OF_NODES="$(yq eval '.nodes | length' cluster.yml)" yq eval -i '
  .nodes[env(NUMBER_OF_NODES)].address = env(HOSTNAME) |
  .nodes[env(NUMBER_OF_NODES)].user = "ubuntu" |
  .nodes[env(NUMBER_OF_NODES)].role[0] = "worker"
' ./cluster.yml

# Upload the cluster.yml file to the S3 bucket
aws s3 cp ./cluster.yml s3://euw1-rke-cluster-config