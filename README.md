This project implements a CI/CD pipeline on AWS using Jenkins and K3s Kubernetes.
Terraform provisions AWS EC2 infrastructure for the cluster and Jenkins server.
Ansible configures Jenkins, Docker, kubectl, and kubeconfig automatically.
On GitHub push, Jenkins clones the repository and builds a Docker image.
The image is pushed securely to Docker Hub for versioned storage.
K3s pulls the latest image and deploys it as Kubernetes pods.
An AWS Application Load Balancer exposes the application to users.
Traffic is routed from ALB → K3s Service → Pods.
The pipeline enables automated, repeatable, and scalable deployments.
Result: production-ready containerized application running on AWS.
