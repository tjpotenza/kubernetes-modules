output "target_group_arns" {
  description = "A list of ARNs for all Target Groups either created by or passed into this module."
  value       = concat(
    values(aws_lb_target_group.cluster_target_groups).*.arn,
    values(data.aws_lb_target_group.from_names).*.arn,
    var.target_group_arns,
  )
}

output "instance_profile_arn" {
  description = "The ARN of the Instance Profile created by this module."
  value       = aws_iam_instance_profile.cluster_member.arn
}

output "security_group_ids" {
  description = "A list of ARNs for all Security Groups either created by or passed into this module."
  value       = concat(
    [ aws_security_group.cluster_member.id ],
    values(data.aws_security_group.from_names).*.id,
    var.security_group_ids,
  )
}

output "cluster_target_groups" {
  description = "A map containing references to the Target Groups managed by this module, with keys matching the input variable of the same name."
  value       = aws_lb_target_group.cluster_target_groups
}
