resource "aws_lb" "k3s_nlb" {
  name               = "k3s-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_1.id]
}

resource "aws_lb_target_group" "k3s_http_tg" {
  name     = "k3s-http-tg"
  port     = 30443
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s_vpc.id
}

resource "aws_lb_listener" "k3s_listener" {
  load_balancer_arn = aws_lb.k3s_nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_http_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "worker_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.k3s_http_tg.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = 30443
}

output "load_balancer_dns" {
  value       = aws_lb.k3s_nlb.dns_name
  description = "DNS do seu cluster para apontar seus domínios"
}