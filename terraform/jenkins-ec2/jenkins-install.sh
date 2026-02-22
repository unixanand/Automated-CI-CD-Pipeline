#!/bin/bash
set -e

# -----------------------------
# Update & install base packages
# -----------------------------
apt update -y
apt upgrade -y
apt install -y curl unzip openjdk-17-jdk docker.io

touch /home/ubuntu/userdata.out
chown ubuntu:ubuntu /home/ubuntu/userdata.out
chmod 644 /home/ubuntu/userdata.out

# -----------------------------
# Docker setup
# -----------------------------
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
echo "Docker + Java installed" >> /home/ubuntu/userdata.out

# -----------------------------
# Install kubectl
# -----------------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
ln -sf /usr/local/bin/kubectl /usr/bin/kubectl
rm kubectl
echo "kubectl installed" >> /home/ubuntu/userdata.out

# -----------------------------
# Install K3s (single-node)
# -----------------------------
curl -sfL https://get.k3s.io | sh -

# Wait for K3s API to be ready
until sudo k3s kubectl get nodes >/dev/null 2>&1; do
    echo "Waiting for K3s to be ready..."
    sleep 5
done

# Setup kubeconfig for ubuntu
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo chmod 600 /home/ubuntu/.kube/config

# Setup kubeconfig for Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod -R 600 /var/lib/jenkins/.kube

echo "K3s ready" >> /home/ubuntu/userdata.out

# -----------------------------
# Install Jenkins
# -----------------------------
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

# Disable setup wizard
echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' >> /etc/default/jenkins

# Add Jenkins to docker group
usermod -aG docker jenkins

# Enable & start Jenkins
systemctl enable jenkins
systemctl start jenkins
systemctl restart jenkins

echo "Jenkins installed and started" >> /home/ubuntu/userdata.out

# -----------------------------
# Detect EC2 public IP and set JENKINS_URL
# -----------------------------
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "JENKINS_URL=http://$PUBLIC_IP:8080/" >> /etc/default/jenkins
echo "JENKINS_URL set with public IP: $PUBLIC_IP" >> /home/ubuntu/userdata.out

# Restart Jenkins to pick up the new URL
systemctl restart jenkins

echo "Jenkins + K3s fully ready" >> /home/ubuntu/userdata.out