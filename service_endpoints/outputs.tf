output "target_group_arns" {
  value = merge({
    shared = aws_lb_target_group.shared_endpoint.arn
  }, {
    for cluster, target_group in aws_lb_target_group.cluster_endpoints:
      cluster => target_group.arn
  })
}