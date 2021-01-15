locals {
  control_plane_external_address_enabled = var.external_dns_zone != "" ? true : false
  control_plane_internal_address_enabled = var.internal_dns_zone != "" ? true : false

  control_plane_external_address         = "control-plane--${var.cluster_name}.${var.external_dns_zone}"
  control_plane_internal_address         = "control-plane--${var.cluster_name}.${var.internal_dns_zone}"

  control_plane_sans = concat(
      local.control_plane_external_address_enabled ? [local.control_plane_external_address] : [],
      local.control_plane_internal_address_enabled ? [local.control_plane_internal_address] : [],
  )
}
