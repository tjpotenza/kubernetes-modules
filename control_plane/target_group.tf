resource "aws_lb_target_group" "external" {
  count                = local.external_ingress_enabled ? 1 : 0
  name                 = "ingress-cluster-external-${var.cluster_name}"
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "ingress-cluster-external-${var.cluster_name}"
  }

  health_check {
    path = "/ping"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "internal" {
  count                = local.internal_ingress_enabled ? 1 : 0
  name                 = "ingress-cluster-internal-${var.cluster_name}"
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "ingress-cluster-internal-${var.cluster_name}"
  }

  health_check {
    path = "/ping"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}
