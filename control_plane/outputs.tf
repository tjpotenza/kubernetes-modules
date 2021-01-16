output "control_plane_external_address" {
  value = local.control_plane_external_address
}

output "control_plane_internal_address" {
  value = local.control_plane_internal_address
}

output "cluster_member_security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "target_group_arn" {
  value = aws_lb_target_group.ingress.arn
}
