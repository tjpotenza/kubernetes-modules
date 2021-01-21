data "aws_region" "current" {}

data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_route53_zone" "external" {
  count = local.external_dns_zone != "" ? 1 : 0
  name  = local.external_dns_zone
}

data "aws_route53_zone" "internal" {
  count        = local.internal_dns_zone != "" ? 1 : 0
  name         = local.internal_dns_zone
  private_zone = true
}

data "aws_lb" "external" {
  count = local.external_ingress_enabled ? 1 : 0
  arn   = lookup(local.external_ingress, "alb_arn", null)
  name  = lookup(local.external_ingress, "alb_name", null)
}

data "aws_lb" "internal" {
  count = local.internal_ingress_enabled ? 1 : 0
  arn   = lookup(local.internal_ingress, "alb_arn", null)
  name  = lookup(local.internal_ingress, "alb_name", null)
}

data "aws_lb_listener" "external" {
  count             = local.external_ingress_enabled ? 1 : 0
  load_balancer_arn = data.aws_lb.external[0].arn
  port              = lookup(local.external_ingress, "alb_port", 443)
}

data "aws_lb_listener" "internal" {
  count             = local.internal_ingress_enabled ? 1 : 0
  load_balancer_arn = data.aws_lb.internal[0].arn
  port              = lookup(local.internal_ingress, "alb_port", 443)
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
