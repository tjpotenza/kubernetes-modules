resource "aws_lb_listener_rule" "cluster_target_groups" {
  for_each = {
    for name, config in var.cluster_target_groups:
      name => config if contains(keys(config), "lb_listener_rule")
  }
  listener_arn = data.aws_lb_listener.cluster_target_groups[each.key].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster_target_groups[each.key].arn
  }

  condition {
    host_header {
      values = [ "*--${var.cluster_name}.${local.region}.${each.value.lb_listener_rule.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(lookup(each.value.lb_listener_rule, "restricted_cidrs", [])) > 0 ? { enabled = true } : {}
    content {
      source_ip {
        values = lookup(each.value.lb_listener_rule, "restricted_cidrs", [])
      }
    }
  }
}
