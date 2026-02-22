#!/bin/bash
set -e

# -----------------------------
# Force non-interactive installs
# -----------------------------
export DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Update system packages
# -----------------------------
apt update -y
apt upgrade -y

# -----------------------------
# Install dependencies: Java, curl, gnupg2, lsb-release, docker, unzip
# -----------------------------
apt install -y openjdk-17-jdk curl gnupg2 lsb-release docker.io unzip

# Log installation
touch /home/ubuntu/userdata.out
chown ubuntu:ubuntu /home/ubuntu/userdata.out
echo "Java, Docker, curl, gnupg2 installed" >> /home/ubuntu/userdata.out

# Enable Docker
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
# Install K3s (single node cluster)
# -----------------------------
curl -sfL https://get.k3s.io | sh -

# Wait for K3s node ready
until kubectl get node >/dev/null 2>&1; do
  sleep 5
done

# Configure .kube for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config

# Configure .kube for Jenkins user (after Jenkins installation)
mkdir -p /var/lib/jenkins/.kube
cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube

echo "K3s installed and .kube config ready for ubuntu and jenkins" >> /home/ubuntu/userdata.out

# -----------------------------
# Install Jenkins
# -----------------------------
# Add Jenkins repo key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list

# Update and install Jenkins
apt update -y
apt install -y jenkins

# Disable setup wizard
echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' > /etc/default/jenkins

# Add Jenkins user to docker group
usermod -aG docker jenkins

# Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins
systemctl status jenkins >> /home/ubuntu/userdata.out

echo "Jenkins installed and running" >> /home/ubuntu/userdata.out

# -----------------------------
# Detect EC2 Public IP and set Jenkins URL
# -----------------------------
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "JENKINS_URL=http://$PUBLIC_IP:8080/" >> /etc/default/jenkins
echo "Public Jenkins URL: http://$PUBLIC_IP:8080/" >> /home/ubuntu/userdata.out

# Restart Jenkins to apply environment
systemctl restart jenkins

echo "Userdata script completed successfully!" >> /home/ubuntu/userdata.out