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

data "aws_security_group" "from_names" {
  for_each = toset(var.security_group_names)
  name     = each.value
}

data "aws_lb_target_group" "from_names" {
  for_each = toset(var.target_group_names)
  name     = each.value
}

data "aws_lb" "cluster_target_groups" {
  for_each = {
    for name, config in var.cluster_target_groups:
      name => config if contains(keys(config), "lb_listener_rule")
  }
  arn      = lookup(each.value.lb_listener_rule, "lb_arn", null)
  name     = lookup(each.value.lb_listener_rule, "lb_name", null)
}

data "aws_lb_listener" "cluster_target_groups" {
  for_each          = {
    for name, config in var.cluster_target_groups:
      name => config if contains(keys(config), "lb_listener_rule")
  }
  load_balancer_arn = data.aws_lb.cluster_target_groups[each.key].arn
  port              = lookup(each.value.lb_listener_rule, "lb_port", 443)
}