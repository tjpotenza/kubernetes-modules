locals {
  etcd_sh = base64encode(templatefile(
    "${path.module}/user_data/etcd/etcd.sh", {
      cluster = var.cluster_name
      role    = "control-plane"
    })
  )

  etcd_install_sh = base64encode(
    templatefile("${path.module}/user_data/etcd/install.sh", {
      etcd_version = "v3.4.15"
    })
  )

  etcd_graceful_shutdown_sh = base64encode(
    templatefile("${path.module}/user_data/etcd/graceful-shutdown.sh", {})
  )

  etcd_service = base64encode(
    templatefile("${path.module}/user_data/etcd/etcd.service", {
      kubernetes_unit = "k3s"
    })
  )
}

locals {
  k3s_install_options = lookup(var.k3s, "version", null) != null ? "INSTALL_K3S_VERSION=${var.k3s.version}" : ""
  k3s_options         = join(" ", lookup(var.k3s, "options", []))

  k3s_admin_yaml = base64encode(
    templatefile("${path.module}/user_data/k3s/admin.yaml", {})
  )
  k3s_node_bootstrapper_yaml = base64encode(
    templatefile("${path.module}/user_data/k3s/node-bootstrapper.yaml", {})
  )

  k3s_graceful_shutdown_service = base64encode(
    templatefile("${path.module}/user_data/k3s/graceful-shutdown.service", {
      kubernetes_unit = "k3s"
    })
  )

  k3s_graceful_shutdown_sh = base64encode(
    templatefile("${path.module}/user_data/k3s/graceful-shutdown.sh", {
      control_plane_address = "localhost"
    })
  )

  k3s_install_sh = base64encode(
    templatefile("${path.module}/user_data/k3s/install.sh", {
      k3s_install_options       = local.k3s_install_options
      k3s_options               = base64encode(local.k3s_options)
      control_plane_sans        = base64encode( join(", ", local.control_plane_sans) )
    })
  )
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "etcd.yaml"
    content_type = "text/cloud-config"
    content      = <<-TEMPLATE
      merge_how:
       - name: list
         settings: [append]
       - name: dict
         settings: [no_replace, recurse_list]
      write_files:
      - path:        "/usr/local/bin/etcd.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.etcd_sh}"
      - path:        "/usr/local/lib/etcd/install.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.etcd_install_sh}"
      - path:        "/usr/local/lib/etcd/graceful-shutdown.sh"
        owner:       "root:root"
        permissions: "0755"
        encoding:    "b64"
        content:     "${local.etcd_graceful_shutdown_sh}"
      - path:        "/etc/systemd/system/etcd.service"
        owner:       "root:root"
        permissions: "0644"
        encoding:    "b64"
        content:     "${local.etcd_service}"
      runcmd:
      - "/usr/local/lib/etcd/install.sh"
      - "sudo systemctl daemon-reload"
      - "sudo systemctl enable etcd.service --now"
    TEMPLATE
  }

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
      - path:        "/var/lib/rancher/k3s/server/manifests/admin.yaml"
        owner:       "root:root"
        permissions: "0600"
        encoding:    "b64"
        content:     "${local.k3s_admin_yaml}"
      - path:        "/var/lib/rancher/k3s/server/manifests/node-bootstrapper.yaml"
        owner:       "root:root"
        permissions: "0600"
        encoding:    "b64"
        content:     "${local.k3s_node_bootstrapper_yaml}"
      runcmd:
      - "/usr/local/lib/k3s/install.sh"
      - "sudo systemctl daemon-reload"
      - "sudo systemctl enable k3s-graceful-shutdown.service --now"
    TEMPLATE
  }
}
