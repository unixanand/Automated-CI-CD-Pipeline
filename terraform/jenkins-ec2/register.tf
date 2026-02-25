resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.streamlit_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 30001
}
