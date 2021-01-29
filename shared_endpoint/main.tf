resource "aws_route53_record" "shared_endpoint" {
  count          = var.dns_record_enabled ? 1 : 0
  zone_id        = data.aws_route53_zone.dns_zone[0].zone_id
  name           = local.endpoint
  set_identifier = "${local.endpoint} - ${local.region}"
  type           = "A"

  alias {
    name    = data.aws_lb.shared_endpoint.dns_name
    zone_id = data.aws_lb.shared_endpoint.zone_id
    evaluate_target_health = true
  }

  latency_routing_policy {
    region = local.region
  }
}

resource "aws_lb_target_group" "shared" {
  count                = local.shared_target_group_enabled ? 1 : 0
  vpc_id               = data.aws_vpc.main.id
  protocol             = local.shared_target_group_protocol
  port                 = local.shared_target_group_port
  deregistration_delay = local.shared_target_group_deregistration_delay

  name  = substr(
    format("%s-%s", "ingress-shared-${var.name}", replace(uuid(), "-", "")),
  0, 32)

  tags = {
    Name = "ingress-shared-${var.name}"
  }

  health_check {
    path = local.shared_target_group_health_check_path
    port = local.shared_target_group_port
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ name ]
  }
}

resource "aws_lb_listener_rule" "shared_endpoint" {
  listener_arn = data.aws_lb_listener.shared_endpoint.arn

  # This dynamic mess is a consequences of a bug / quirk with aws_lb_listener_rule resource.  It will
  # not allow an action { forward { ... } } block to have only one target_group {} blocks, so we need
  # a special case for when there's only one target_group associated versus when there are many.
  dynamic "action" {
    for_each = length(local.target_group_arns) == 1 ? local.target_group_arns : {}
    content {
      type             = "forward"
      target_group_arn = action.value
    }
  }

  dynamic "action" {
    for_each = length(local.target_group_arns) > 1 ? { exists = true } : {}
    content {
    type = "forward"
      forward {
        stickiness {
          enabled  = var.stickiness_enabled
          duration = var.stickiness_duration
        }

        dynamic "target_group" {
          for_each = local.target_group_arns
          content {
            arn    = target_group.value
            weight = lookup(var.weights, target_group.key, 1)
          }
        }
      }
    }
  }

  condition {
    host_header {
      values = [ local.endpoint ]
    }
  }

  dynamic "condition" {
    for_each = length(var.restricted_cidrs) > 0 ? { exists = true } : {}
    content {
      source_ip {
        values = var.restricted_cidrs
      }
    }
  }
}
