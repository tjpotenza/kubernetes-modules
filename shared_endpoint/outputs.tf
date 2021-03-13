output "shared_target_group_arn" {
  description = "ARN of the shared target group, if one was created."
  value       = concat( aws_lb_target_group.shared_endpoint.*.arn, [null] )[0]
}
