locals {
  master_address     = "master--${var.cluster_name}.${var.dns_zone}"
  node_token_address = "node-token--${var.cluster_name}.${var.dns_zone}"
}
