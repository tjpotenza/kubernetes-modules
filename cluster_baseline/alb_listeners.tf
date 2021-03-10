resource "aws_lb_listener_rule" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "load_balancer") && contains(keys(config), "dns_zone")
  }
  listener_arn = data.aws_lb_listener.ingress[each.key].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress[each.key].arn
  }

  condition {
    host_header {
      values = [ "*--${var.cluster_name}.${local.region}.${each.value.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(lookup(each.value.load_balancer, "restricted_cidrs", [])) > 0 ? { enabled = true } : {}
    content {
      source_ip {
        values = lookup(each.value.load_balancer, "restricted_cidrs", [])
      }
    }
  }
}
