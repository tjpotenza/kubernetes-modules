data "aws_region" "current" {}

data "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0
  tags  = var.vpc_tags
}

locals {
  vpc_id = (var.vpc_id == null ? data.aws_vpc.main[0].id : var.vpc_id)
}

data "aws_subnet_ids" "main" {
  count  = var.subnet_ids == null ? 1 : 0
  vpc_id = local.vpc_id

  dynamic "filter" {
    for_each = var.subnet_filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

locals {
  subnet_ids = (var.subnet_ids == null ? data.aws_subnet_ids.main[0].ids : var.subnet_ids)
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
