################################################################################
# Target Group for Ingress Routing
################################################################################
resource "aws_lb_target_group" "ingress" {
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "ingress-cluster-${var.cluster_name}"
  }

  health_check {
    path = "/ping"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Ingress Routing
################################################################################
resource "aws_lb_listener_rule" "local_public" {
  count        = length(var.public_ingress_hostnames) > 0 ? 1 : 0
  listener_arn = data.aws_lb_listener.ingress.arn
  priority     = var.alb_rule_priorities[0]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  condition {
    host_header {
      values = var.public_ingress_hostnames
    }
  }
}

resource "aws_lb_listener_rule" "local_private" {
  count        = 1 # Just for statefile sanity since the other listener's optional
  listener_arn = data.aws_lb_listener.ingress.arn
  priority     = var.alb_rule_priorities[1]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  condition {
    host_header {
      values = concat(
        ["*--${var.cluster_name}.${var.dns_zone}"],
        var.private_ingress_hostnames
      )
    }
  }
  condition {
    source_ip {
      values = var.private_cidrs
    }
  }
}
