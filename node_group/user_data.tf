################################################################################
# Rendering files for k3s (node)
################################################################################
locals {
  k3s_install_options = lookup(var.k3s, "version", null) != null ? "INSTALL_K3S_VERSION=${var.k3s.version}" : ""
  k3s_options         = join(" ", lookup(var.k3s, "options", []))

  k3s_discover_control_plane_sh = base64encode(
    templatefile("${path.module}/user_data/k3s/discover-control-plane.sh", {
      cluster = var.cluster_name
    })
  )

  k3s_graceful_shutdown_service = base64encode(
    templatefile("${path.module}/user_data/k3s/graceful-shutdown.service", {
      kubernetes_unit = "k3s-agent"
    })
  )

  k3s_graceful_shutdown_sh = base64encode(
    templatefile("${path.module}/user_data/k3s/graceful-shutdown.sh", {
      control_plane_address = "control-plane.cluster.local"
    })
  )

  k3s_install_sh = base64encode(
    templatefile("${path.module}/user_data/k3s/install.sh", {
      k3s_install_options   = local.k3s_install_options
      k3s_options           = local.k3s_options
    })
  )
}

################################################################################
# Compiling everything into the cloud-init config itself
################################################################################
data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "k3s.yaml"
    content_type = "text/cloud-config"
    content      = <<-TEMPLATE
      merge_how:
       - name: list
         settings: [append]
       - name: dict
         settings: [no_replace, recurse_list]
      write_files:
      - path:        "/usr/local/lib/k3s/install.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.k3s_install_sh}"
      - path:        "/usr/local/lib/k3s/discover-control-plane.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.k3s_discover_control_plane_sh}"
      - path:        "/usr/local/lib/k3s/graceful-shutdown.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.k3s_graceful_shutdown_sh}"
      - path:        "/etc/systemd/system/k3s-graceful-shutdown.service"
        owner:       "root:root"
        permissions: "0644"
        encoding:    "b64"
        content:     "${local.k3s_graceful_shutdown_service}"
      runcmd:
      - "/usr/local/lib/k3s/install.sh"
      - "sudo systemctl daemon-reload"
      - "sudo systemctl enable k3s-graceful-shutdown.service --now"
    TEMPLATE
  }
}