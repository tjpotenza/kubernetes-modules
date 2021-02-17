output "external_control_plane_address" {
  value = local.external_control_plane_address
}

output "internal_control_plane_address" {
  value = local.internal_control_plane_address
}

output "cluster_member_security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "target_group_arns" {
  value = {
    internal = local.internal_ingress_enabled ? aws_lb_target_group.internal[0].arn : null
    external = local.external_ingress_enabled ? aws_lb_target_group.external[0].arn : null
  }
}
