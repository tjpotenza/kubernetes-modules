resource "aws_lb_listener_rule" "shared_endpoint" {
  listener_arn = data.aws_lb_listener.shared_endpoint.arn

  # This absolute dynamic nightmare's a consequences of a bug / quirk with aws_lb_listener_rule resource.
  # It will not allow an action { forward { ... } } block to have only one target_group {} blocks, so we
  # need a special case for when there's only one target_group associated versus when there are many.

  dynamic "action" {
    for_each = length(local.shared_endpoint_target_group_arns) == 1 ? local.shared_endpoint_target_group_arns : {}
    content {
      type             = "forward"
      target_group_arn = action.value
    }
  }

  dynamic "action" {
    for_each = length(local.shared_endpoint_target_group_arns) > 1 ? { iterate = "once" } : {}
    content {
    type = "forward"
      forward {
        dynamic "target_group" {
          for_each = local.shared_endpoint_target_group_arns
          content {
            arn = target_group.value
          }
        }
      }
    }
  }

  condition {
    host_header {
      values = [ "${var.name}.${var.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(var.cluster_endpoints_ingress_cidrs) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = var.cluster_endpoints_ingress_cidrs
      }
    }
  }
}


resource "aws_lb_listener_rule" "cluster_endpoints" {
  for_each     = local.cluster_endpoints_clusters
  listener_arn = data.aws_lb_listener.cluster_endpoints.arn

  action {
    type             = "forward"
    target_group_arn = local.shared_endpoint_target_group_arns[each.value]
  }

  condition {
    host_header {
      values = [ "${var.name}--${each.value}.${var.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(var.cluster_endpoints_ingress_cidrs) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = var.cluster_endpoints_ingress_cidrs
      }
    }
  }
}
