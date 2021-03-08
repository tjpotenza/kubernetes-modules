locals {
  kubernetes_unit = "k3s"

  etcd = {
    data_dir = "/var/lib/etcd"
  }

  etcd_sh = base64encode(
    templatefile("${path.module}/userdata/etcd/etcd.sh", {
      cluster = var.cluster_name
      role    = "control-plane"
    })
  )

  etcd_install_sh = base64encode(
    templatefile("${path.module}/userdata/etcd/install.sh", {
      etcd_version = "v3.4.15"
    })
  )

  etcd_graceful_shutdown_sh = base64encode(
    templatefile("${path.module}/userdata/etcd/graceful-shutdown.sh", {})
  )

  etcd_service = base64encode(
    templatefile("${path.module}/userdata/etcd/etcd.service", {
      kubernetes_unit = "k3s"
    })
  )
}

data "template_cloudinit_config" "ha_nodes" {
  for_each      = var.ha_enabled ? { if_enabled = true } : {}
  gzip          = true
  base64_encode = true

  part {
    filename     = "etcd.yaml"
    content_type = "text/cloud-config"
    content      = <<-TEMPLATE
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

  # part {
  #   content_type = "text/x-shellscript"
  #   content      = templatefile("${path.module}/userdata/etcd.sh", {
  #     cluster = var.cluster_name
  #     role    = "control-plane"
  #   })
  # }
}

resource "aws_instance" "ha_nodes" {
  count                  = var.ha_enabled ? var.instances : 0
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data_base64       = data.template_cloudinit_config.ha_nodes["if_enabled"].rendered
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
