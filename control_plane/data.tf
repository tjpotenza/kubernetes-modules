data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_route53_zone" "ingress" {
  name = var.dns_zone
}

data "aws_route53_zone" "ingress_internal" {
  name         = var.dns_zone
  private_zone = true
}

data "aws_lb" "ingress" {
  name = var.ingress_lb_name
}

data "aws_lb_listener" "ingress" {
  load_balancer_arn = data.aws_lb.ingress.arn
  port              = var.ingress_lb_listener_port
}

data "aws_ami" "ami" {
  name_regex  = var.ami_regex
  owners      = ["amazon"]
  most_recent = true
}

data "aws_security_group" "instance" {
  for_each = toset(var.security_group_names)
  name     = each.value
}
