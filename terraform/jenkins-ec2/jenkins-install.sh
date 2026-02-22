#!/bin/bash
set -e

apt update -y
apt upgrade -y
apt install -y curl unzip openjdk-17-jdk docker.io

touch /home/ubuntu/userdata.out
chown ubuntu:ubuntu /home/ubuntu/userdata.out

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
ln -s /usr/local/bin/kubectl /usr/bin/kubectl || true
rm kubectl

# -----------------------------
# Install K3s
# -----------------------------
curl -sfL https://get.k3s.io | sh -

until kubectl get node >/dev/null 2>&1; do
  sleep 5
done

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "K3s ready" >> /home/ubuntu/userdata.out

# -----------------------------
# Install Jenkins
# -----------------------------
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' >> /etc/default/jenkins

usermod -aG docker jenkins

mkdir -p /var/lib/jenkins/.kube
cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube

systemctl enable jenkins
systemctl start jenkins
systemctl restart jenkins

echo "Jenkins + K3s fully ready" >> /home/ubuntu/userdata.out

# -----------------------------
# Detect EC2 public IP
# -----------------------------
PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
echo "JENKINS_URL=http://$PUBLIC_IP:8080/" >> /etc/default/jenkins
echo "Public-Ip has written to /etc/environment" >> /home/ubuntu/userdata.out

systemctl restart jenkins