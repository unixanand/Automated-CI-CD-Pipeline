terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -------------------------
# Get latest Ubuntu 22.04
# -------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -------------------------
# Local secret file (GitHub-safe)
# -------------------------
data "local_file" "docker_secret" {
  filename = "${path.module}/secret"  #  local secret file
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "k8s_sg" {
  name_prefix = "k8s-sg-"
  description = "Allow SSH and Kubernetes ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

# -------------------------
# Jenkins EC2
# -------------------------
resource "aws_instance" "jenkins_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  key_name                    = "my-amazon-linux-key"
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  # Userdata: inject local secret into /etc/environment
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update packages
              apt update -y && apt upgrade -y

              # Append local secret from Terraform
              echo "${data.local_file.docker_secret.content}" >> /etc/environment
              
              # Continue with your existing jenkins-install.sh commands
              ${file("jenkins-install.sh")}
              EOF

  tags = {
    Name = "Jenkins-server"
    Env  = "Dev"
  }
}

# -------------------------
# Dynamic Ansible inventory
# -------------------------
resource "local_file" "ansible_inventory" {
  content = <<EOT
[devops]
${aws_instance.jenkins_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-amazon-linux-key.pem
EOT

  filename = "../../ansible/inventory.ini"
}