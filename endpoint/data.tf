data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_lb" "ingress" {
  name = var.ingress_lb_name
}

data "aws_lb_listener" "ingress" {
  load_balancer_arn = data.aws_lb.ingress.arn
  port              = var.ingress_lb_listener_port
}
