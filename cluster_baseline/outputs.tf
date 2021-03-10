output "target_group_arns" {
  value = concat(
    values(aws_lb_target_group.ingress).*.arn,
    values(data.aws_lb_target_group.from_names).*.arn,
    var.target_group_arns,
  )
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.cluster_member.arn
}

output "security_group_ids" {
  value = concat(
    [ aws_security_group.cluster_member.id ],
    values(data.aws_security_group.from_names).*.id,
    var.security_group_ids,
  )
}
