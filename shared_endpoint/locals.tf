locals {
  region      = data.aws_region.current.name
  dns_zone_id = var.dns_record_enabled ? data.aws_route53_zone.dns_zone[0].zone_id : ""
  dns_zone    = var.dns_record_enabled ? data.aws_route53_zone.dns_zone[0].name : ""
  endpoint    = "${var.name}.${local.dns_zone}"

  shared_target_group_enabled              = lookup(var.shared_target_group, "enabled", false)
  shared_target_group_protocol             = lookup(var.shared_target_group, "protocol", "HTTP")
  shared_target_group_port                 = lookup(var.shared_target_group, "port", 80)
  shared_target_group_deregistration_delay = lookup(var.shared_target_group, "deregistration_delay", 60)
  shared_target_group_health_check_path    = lookup(var.shared_target_group, "health_check_path", "/ping")

  target_group_arns = merge(
    var.target_group_arns,
    local.shared_target_group_enabled ? { shared = aws_lb_target_group.shared_endpoint[0].arn } : {}
  )
}
