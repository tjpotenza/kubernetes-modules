################################################################################
# Target Group Per Cluster
################################################################################
resource "aws_lb_target_group" "shared_endpoint" {
  name                 = "${var.name}--shared"
  protocol             = "HTTP"
  port                 = var.target_port
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "${var.name}--shared"
  }

  health_check {
    path = var.healthcheck_path
    port = var.target_port
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "cluster_endpoints" {
  for_each             = local.clusters
  name                 = "${var.name}--${each.value}"
  protocol             = "HTTP"
  port                 = var.target_port
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "${var.name}--${each.value}"
  }

  health_check {
    path = var.healthcheck_path
    port = var.target_port
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Shared Endpoint
################################################################################
resource "aws_route53_record" "shared_endpoint" {
  zone_id        = data.aws_route53_zone.dns_zone.zone_id
  name           = "${var.name}.${var.dns_zone}"
  set_identifier = "${var.name}.${var.dns_zone} - ${local.region}"
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

resource "aws_lb_listener_rule" "shared_endpoint" {
  listener_arn = data.aws_lb_listener.shared_endpoint.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shared_endpoint.arn
  }

  condition {
    host_header {
      values = [ "${var.name}.${var.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(local.shared_endpoint_ingress_cidrs) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = local.shared_endpoint_ingress_cidrs
      }
    }
  }
}

################################################################################
# Cluster Endpoints
################################################################################
resource "aws_route53_record" "cluster_endpoints" {
  for_each = local.cluster_endpoints_clusters
  zone_id  = data.aws_route53_zone.dns_zone.zone_id
  name     = "${var.name}--${each.value}.${var.dns_zone}"
  type     = "A"

  alias {
    name    = data.aws_lb.cluster_endpoints.dns_name
    zone_id = data.aws_lb.cluster_endpoints.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener_rule" "cluster_endpoints" {
  for_each     = local.cluster_endpoints_clusters
  listener_arn = data.aws_lb_listener.cluster_endpoints.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster_endpoints[each.value].arn
  }

  condition {
    host_header {
      values = [ "${var.name}--${each.value}.${var.dns_zone}" ]
    }
  }

  dynamic "condition" {
    for_each = length(local.cluster_endpoints_ingress_cidrs) > 0 ? {private = true} : {}
    content {
      source_ip {
        values = local.cluster_endpoints_ingress_cidrs
      }
    }
  }
}
