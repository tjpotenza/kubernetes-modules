output "security_group_id" {
  value = aws_security_group.cluster_member.id
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.ingress: k => v.arn }
}

output "single_node_id" {
  value = ""
}

output "iam_instance_profile_arn" {
  value = aws_iam_instance_profile.control_plane.arn
}