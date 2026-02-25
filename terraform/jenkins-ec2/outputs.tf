# -------------------------
# Outputs
# -------------------------
output "Jenkins_Server_Public_Ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "app_url" {
  value = aws_lb.app_alb.dns_name
}

