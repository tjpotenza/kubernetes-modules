resource "aws_lb_listener_rule" "external" {
  count        = local.external_ingress_enabled ? 1 : 0
  listener_arn = data.aws_lb_listener.external[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  condition {
    host_header {
      values = [ "*--${var.cluster_name}.${local.region}.${local.external_dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(lookup(local.external_ingress, "restricted_cidrs", [])) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = lookup(local.external_ingress, "restricted_cidrs", [])
      }
    }
  }
}

resource "aws_lb_listener_rule" "internal" {
  count        = local.internal_ingress_enabled ? 1 : 0
  listener_arn = data.aws_lb_listener.internal[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  condition {
    host_header {
      values = [ "*--${var.cluster_name}.${local.region}.${var.internal_dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(lookup(local.internal_ingress, "restricted_cidrs", [])) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = lookup(local.internal_ingress, "restricted_cidrs", [])
      }
    }
  }
}
