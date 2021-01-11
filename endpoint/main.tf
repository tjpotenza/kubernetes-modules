resource "aws_lb_target_group" "ingress" {
  protocol             = "HTTP"
  port                 = var.port
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "ingress-cluster-${var.name}"
  }

  health_check {
    path = var.healthcheck_path
    port = var.port
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "ingress" {
  listener_arn = data.aws_lb_listener.ingress.arn
  priority     = var.alb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  condition {
    host_header {
      values = var.hostnames
    }
  }

  dynamic "condition" {
    for_each = var.private ? {private = true} : {}
    content {
      source_ip {
        values = var.private_cidrs
      }
    }
  }
}
