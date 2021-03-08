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
  k3s_worker_bootstrapper_yaml = base64encode(
    templatefile("${path.module}/user_data/k3s/worker-bootstrapper.yaml", {})
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
      - path:        "/var/lib/rancher/k3s/server/manifests/worker-bootstrapper.yaml"
        owner:       "root:root"
        permissions: "0600"
        encoding:    "b64"
        content:     "${local.k3s_worker_bootstrapper_yaml}"
      runcmd:
      - "/usr/local/lib/k3s/install.sh"
      - "sudo systemctl daemon-reload"
      - "sudo systemctl enable k3s-graceful-shutdown.service --now"
    TEMPLATE
  }
}

resource "aws_instance" "ha_nodes" {
  count                  = var.ha_enabled ? var.instances : 0
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data_base64       = data.template_cloudinit_config.user_data.rendered
  iam_instance_profile   = aws_iam_instance_profile.control_plane.id
  subnet_id              = length(local.subnet_ids) == 1 ? local.subnet_ids[0] : null
  vpc_security_group_ids = concat(
    values(data.aws_security_group.instance).*.id,
    var.security_group_ids,
    [ aws_security_group.cluster_member.id ],
  )

  root_block_device {
    volume_type           = lookup(var.root_block_device, "volume_type", null)
    volume_size           = lookup(var.root_block_device, "volume_size", null)
    iops                  = lookup(var.root_block_device, "iops", null)
    delete_on_termination = lookup(var.root_block_device, "delete_on_termination", null)
    encrypted             = lookup(var.root_block_device, "encrypted", null)
  }

  dynamic "credit_specification" {
    for_each = var.instance_cpu_credits != null ? { enabled = true } : {}
    content {
      cpu_credits = var.instance_cpu_credits
    }
  }

  tags = merge(
    {
      Name    = "${var.cluster_name}-control-plane"
      Cluster = var.cluster_name
      Role    = "control-plane"
    },
    {
      for name, config in var.ingress:
        "${title(name)}Address" =>  "control-plane--${var.cluster_name}.${local.region}.${config.dns_zone}" if contains(keys(config), "dns_zone")
    }
  )
}
