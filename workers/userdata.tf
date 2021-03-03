locals {
  k3s_install_options = join(" ", [
    var.k3s_version != "" ? "INSTALL_K3S_VERSION=${var.k3s_version}" : "INSTALL_K3S_CHANNEL=${var.k3s_channel}"
  ])
}

####################################################################################################
# Config Files
####################################################################################################

data "template_file" "graceful_shutdown_service" {
  template = file("${path.module}/userdata/graceful-shutdown.service")
  vars     = {
    kubernetes_unit = "k3s-agent"
  }
}

data "template_file" "graceful_shutdown_sh" {
  template = file("${path.module}/userdata/graceful-shutdown.sh")
  vars     = {
    control_plane_address = var.control_plane_address
  }
}

####################################################################################################
# Bootstrapping Script
####################################################################################################
data "template_file" "bootstrap_sh" {
  template = file("${path.module}/userdata/bootstrap.sh")
  vars = {
    k3s_install_options       = local.k3s_install_options
    control_plane_address     = base64encode(var.control_plane_address)
    graceful_shutdown_service = base64encode(data.template_file.graceful_shutdown_service.rendered)
    graceful_shutdown_sh      = base64encode(data.template_file.graceful_shutdown_sh.rendered)
  }
}
