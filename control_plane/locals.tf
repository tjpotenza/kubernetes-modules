locals {
  region = data.aws_region.current.name

  external_dns_zone = lookup(var.external, "dns_zone", "")
  internal_dns_zone = lookup(var.internal, "dns_zone", "")
  external_ingress  = lookup(var.external, "ingress", {})
  internal_ingress  = lookup(var.internal, "ingress", {})

  external_control_plane_address = "control-plane--${var.cluster_name}.${local.region}.${local.external_dns_zone}"
  internal_control_plane_address = "control-plane--${var.cluster_name}.${local.region}.${local.internal_dns_zone}"

  control_plane_sans = concat(
    local.external_control_plane_address != "" ? [local.external_control_plane_address] : [],
    local.internal_control_plane_address != "" ? [local.internal_control_plane_address] : [],
  )

  external_ingress_enabled = local.external_dns_zone != "" && lookup(local.external_ingress, "alb_arn", "") != ""
  internal_ingress_enabled = local.internal_dns_zone != "" && lookup(local.internal_ingress, "alb_arn", "") != ""
}
