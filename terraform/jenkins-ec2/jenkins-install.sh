#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# -----------------------------
# System update
# -----------------------------
apt update -y
apt upgrade -y

# -----------------------------
# Install base dependencies
# -----------------------------
apt install -y \
  openjdk-21-jre \
  curl \
  gnupg2 \
  lsb-release \
  docker.io \
  unzip \
  fontconfig \
  wget

# -----------------------------
# Log file
# -----------------------------
LOG_FILE="/home/ubuntu/userdata.out"
touch $LOG_FILE
chown ubuntu:ubuntu $LOG_FILE
echo "Base packages installed" >> $LOG_FILE

# -----------------------------
# Enable Docker
# -----------------------------
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
echo "Docker enabled" >> $LOG_FILE

# -----------------------------
# Install kubectl
# -----------------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
ln -sf /usr/local/bin/kubectl /usr/bin/kubectl || true
rm kubectl
echo "kubectl installed" >> $LOG_FILE

# -----------------------------
# Install K3s
# -----------------------------
curl -sfL https://get.k3s.io | sh -

until kubectl get nodes >/dev/null 2>&1; do
  sleep 5
done

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config
echo "K3s installed" >> $LOG_FILE

# =====================================================
# Install Jenkins (Official APT method)
# =====================================================
echo "Installing Jenkins..." >> $LOG_FILE

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ \
  > /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

systemctl enable jenkins
systemctl start jenkins

echo "Jenkins installed and started" >> $LOG_FILE

# Wait for Jenkins to initialize
sleep 30

echo "Jenkins initial admin password:" >> $LOG_FILE
cat /var/lib/jenkins/secrets/initialAdminPassword >> $LOG_FILE

# -----------------------------
# Open firewall port if UFW exists
# -----------------------------
ufw allow 8080 || true

# -----------------------------
# Done
# -----------------------------
echo "Userdata completed successfully!" >> $LOG_FILE