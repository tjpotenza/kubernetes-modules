output "shared_target_group_arn" {
  value = concat( aws_lb_target_group.shared.*.arn, [null] )[0]
}
