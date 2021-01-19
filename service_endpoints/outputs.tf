output "target_group_arns" {
  value = {
    for cluster, target_group in aws_lb_target_group.per_cluster:
      cluster => target_group.arn
  }
}