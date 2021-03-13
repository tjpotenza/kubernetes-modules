locals {
  role_name = "control-plane"

  control_plane_sans = concat(
    var.control_plane_sans,
    [ "control-plane.cluster.local" ]
  )
}
