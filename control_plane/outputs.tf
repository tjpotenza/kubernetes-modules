output "external_control_plane_address" {
  value = local.external_control_plane_address
}

output "internal_control_plane_address" {
  value = local.internal_control_plane_address
}

output "cluster_member_security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "target_group_arn" {
  value = aws_lb_target_group.ingress.arn
}
