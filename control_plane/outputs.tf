output "security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "control_plane_addresses" {
  value = { for k, v in aws_route53_record.ingress: k => v.name }
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.ingress: k => v.arn }
}
