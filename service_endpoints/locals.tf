locals {
  region = data.aws_region.current.name

  clusters = toset(distinct(concat(
    lookup(var.shared_endpoint,   "clusters", []),
    lookup(var.cluster_endpoints, "clusters", []),
  )))

  shared_endpoint_type            =       lookup(var.shared_endpoint,   "type",          "external")
  shared_endpoint_ingress_cidrs   =       lookup(var.shared_endpoint,   "ingress_cidrs", [])
  shared_endpoint_clusters        = toset(lookup(var.shared_endpoint,   "clusters",      []))

  cluster_endpoints_type          =       lookup(var.cluster_endpoints, "type",          "external")
  cluster_endpoints_ingress_cidrs =       lookup(var.cluster_endpoints, "ingress_cidrs", [])
  cluster_endpoints_clusters      = toset(lookup(var.cluster_endpoints, "clusters",      []))
}
