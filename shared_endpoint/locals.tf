locals {
  region   = data.aws_region.current.name
  endpoint = "${var.name}.${var.dns_zone}"

  shared_target_group_enabled              = lookup(var.shared_target_group, "enabled", false)
  shared_target_group_protocol             = lookup(var.shared_target_group, "protocol", "HTTP")
  shared_target_group_port                 = lookup(var.shared_target_group, "port", 80)
  shared_target_group_deregistration_delay = lookup(var.shared_target_group, "deregistration_delay", 60)
  shared_target_group_health_check_path    = lookup(var.shared_target_group, "health_check_path", "/ping")

  target_group_arns = merge(
    var.target_group_arns,
    local.shared_target_group_enabled ? { shared = aws_lb_target_group.shared[0].arn } : {}
  )
}
