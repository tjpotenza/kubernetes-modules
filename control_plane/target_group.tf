resource "random_string" "target_group_nonce" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ingress" {
  for_each             = var.ingress
  name                 = "cluster-${var.cluster_name}-${each.key}-${random_string.target_group_nonce.result}"
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = local.vpc_id
  deregistration_delay = 60

  tags = {
    Name = "cluster-${var.cluster_name}-${each.key}"
    name = "cluster-${var.cluster_name}-${each.key}"
  }

  health_check {
    path = "/ping"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}
