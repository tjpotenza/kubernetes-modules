resource "random_string" "target_group_nonce" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ingress" {
  for_each             = var.ingress
  name                 = substr("${random_string.target_group_nonce.result}-${var.cluster_name}-${each.key}", 0, 32)
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = local.vpc_id
  deregistration_delay = 60

  tags = {
    Cluster = var.cluster_name
    Type    = each.key
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
