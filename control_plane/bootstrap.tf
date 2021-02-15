locals {
  k3s_install_options = join(" ", [
    var.k3s_version != "" ? "INSTALL_K3S_VERSION=${var.k3s_version}" : "INSTALL_K3S_CHANNEL=${var.k3s_channel}"
  ])
}

data "template_file" "admin_yml" {
  template = file("${path.module}/bootstrap/admin.yml")
}

data "template_file" "node_token_yml" {
  template = file("${path.module}/bootstrap/node_token.yml")
}

data "template_file" "bootstrap_sh" {
  template = file("${path.module}/bootstrap/bootstrap.sh")
  vars = {
    control_plane_sans  = join("\n", [for san in local.control_plane_sans: "  - ${san}"])
    k3s_install_options = local.k3s_install_options
    admin_yml           = data.template_file.admin_yml.rendered
    node_token_yml      = data.template_file.node_token_yml.rendered
  }
}
