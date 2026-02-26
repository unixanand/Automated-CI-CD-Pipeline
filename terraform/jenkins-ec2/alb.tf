resource "aws_lb" "app_alb" {
  name               = "streamlit-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s_sg.id]
  subnets            = data.aws_subnets.default.ids
}
