#!/bin/bash
set -e

# -----------------------------
# Non-interactive install
# -----------------------------
export DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Update system packages
# -----------------------------
apt update -y
apt upgrade -y

# -----------------------------
# Install dependencies: Java, curl, gnupg2, lsb-release, unzip, docker
# -----------------------------
apt install -y openjdk-17-jdk curl gnupg2 lsb-release docker.io unzip

# -----------------------------
# Log file
# -----------------------------
touch /home/ubuntu/userdata.out
chown ubuntu:ubuntu /home/ubuntu/userdata.out
echo "Java, Docker, curl, gnupg2 installed" >> /home/ubuntu/userdata.out

# -----------------------------
# Enable Docker
# -----------------------------
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
echo "Docker enabled and ubuntu added to docker group" >> /home/ubuntu/userdata.out

# -----------------------------
# Install kubectl
# -----------------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
ln -sf /usr/local/bin/kubectl /usr/bin/kubectl || true
rm kubectl
echo "kubectl installed" >> /home/ubuntu/userdata.out

# -----------------------------
# Install K3s (single node)
# -----------------------------
curl -sfL https://get.k3s.io | sh -

# Wait for K3s node ready
until kubectl get nodes >/dev/null 2>&1; do
  sleep 5
done

# Configure kubeconfig for ubuntu
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config

echo "K3s installed and kubeconfig ready for ubuntu" >> /home/ubuntu/userdata.out

# -----------------------------
# Run Jenkins container
# -----------------------------
docker network create jenkins-net || true

docker run -d \
  --name jenkins \
  --network jenkins-net \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/ubuntu/.kube:/var/jenkins_home/.kube \
  jenkins/jenkins:lts-jdk17

echo "Jenkins container started" >> /home/ubuntu/userdata.out

# -----------------------------
# Wait for Jenkins container to initialize
# -----------------------------
sleep 30
docker logs jenkins | tail -n 20 >> /home/ubuntu/userdata.out

# -----------------------------
# Generate Ansible inventory
# -----------------------------

echo "Userdata completed successfully!" >> /home/ubuntu/userdata.out