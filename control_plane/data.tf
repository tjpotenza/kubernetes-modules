data "aws_region" "current" {}

data "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0
  tags  = var.vpc_tags
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

data "aws_route53_zone" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "dns_zone")
  }
  name         = each.value.dns_zone
  private_zone = lookup(each.value, "internal", false)
}

data "aws_lb" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "load_balancer")
  }
  arn      = lookup(each.value.load_balancer, "arn", null)
  name     = lookup(each.value.load_balancer, "name", null)
}

data "aws_lb_listener" "ingress" {
  for_each          = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "load_balancer")
  }
  load_balancer_arn = data.aws_lb.ingress[each.key].arn
  port              = lookup(each.value.load_balancer, "alb_port", 443)
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
