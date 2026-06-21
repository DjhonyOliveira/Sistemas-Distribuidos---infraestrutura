# 1. Definição do Network Load Balancer (NLB)
resource "aws_lb" "k3s_nlb" {
  name               = "k3s-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_1.id]
}

# ==========================================
# ROTA A: APLICAÇÃO - TRÁFEGO HTTP (PORTA 80)
# Traefik (web) fixado em NodePort 30080 via HelmChartConfig (k3s-install.tf)
# ==========================================

resource "aws_lb_target_group" "app_http_tg" {
  name     = "k3s-app-http-tg"
  port     = 30080
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "app_http_listener" {
  load_balancer_arn = aws_lb.k3s_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_http_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_http_worker_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_http_tg.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "app_http_master_attachment" {
  target_group_arn = aws_lb_target_group.app_http_tg.arn
  target_id        = aws_instance.k3s_master.id
  port             = 30080
}

# ==========================================
# ROTA B: APLICAÇÃO - TRÁFEGO HTTPS (PORTA 443)
# Traefik (websecure) fixado em NodePort 30443 via HelmChartConfig (k3s-install.tf)
# ==========================================

resource "aws_lb_target_group" "app_https_tg" {
  name     = "k3s-app-https-tg"
  port     = 30443
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "app_https_listener" {
  load_balancer_arn = aws_lb.k3s_nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_https_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_https_worker_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_https_tg.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = 30443
}

resource "aws_lb_target_group_attachment" "app_https_master_attachment" {
  target_group_arn = aws_lb_target_group.app_https_tg.arn
  target_id        = aws_instance.k3s_master.id
  port             = 30443
}

# ==========================================
# ROTA C: ARGOCD - PORTA EXCLUSIVA (PORTA 8080)
# ArgoCD fixado em NodePort 30943 (https) via helm values (argocd.tf),
# separado dos NodePorts do Traefik para não colidir com o tráfego da app.
# ==========================================

resource "aws_lb_target_group" "argocd_tg" {
  name     = "k3s-argocd-tg"
  port     = 30943
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "argocd_listener" {
  load_balancer_arn = aws_lb.k3s_nlb.arn
  port              = 8080
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "argocd_worker_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.argocd_tg.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = 30943
}

resource "aws_lb_target_group_attachment" "argocd_master_attachment" {
  target_group_arn = aws_lb_target_group.argocd_tg.arn
  target_id        = aws_instance.k3s_master.id
  port             = 30943
}

# ==========================================
# OUTPUTS
# ==========================================

output "load_balancer_dns" {
  value       = aws_lb.k3s_nlb.dns_name
  description = "DNS do cluster para apontar domínios"
}