output "security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "control_plane_addresses" {
  value = { for k, v in aws_route53_record.ingress: k => v.name }
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.ingress: k => v.arn }
}

output "single_node_id" {
  value = var.ha_enabled ? null : aws_instance.single_node[0].id
}
