output "shared_target_group_arn" {
  value = concat( aws_lb_target_group.shared_endpoint.*.arn, [null] )[0]
}
