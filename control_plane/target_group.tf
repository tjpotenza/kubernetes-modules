resource "aws_lb_target_group" "ingress" {
  name                 = "ingress-cluster-${var.cluster_name}"
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
