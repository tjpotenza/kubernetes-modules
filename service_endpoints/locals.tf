locals {
  region                            = data.aws_region.current.name
  cluster_endpoints_clusters        = toset(var.cluster_endpoints_clusters[local.region])
  shared_endpoint_target_group_arns = var.cluster_target_group_arns[local.region]
}
