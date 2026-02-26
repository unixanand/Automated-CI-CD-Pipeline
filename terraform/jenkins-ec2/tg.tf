resource "aws_lb_target_group" "streamlit_tg" {
  name     = "streamlit-app-tg"
  port     = 30001
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/_stcore/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}
