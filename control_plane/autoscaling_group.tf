resource "random_string" "group_nonce" {
  length  = 6
  upper   = false
  special = false
  keepers = {
    cluster_name = var.cluster_name
  }
}

locals {
  group_name = "${ substr("${var.cluster_name}-${local.role_name}", 0, 25) }-${ random_string.group_nonce.result }"
}

resource "aws_launch_template" "instances" {
  name_prefix            = local.group_name
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = data.template_cloudinit_config.user_data.rendered
  vpc_security_group_ids = concat(
    values(data.aws_security_group.from_names).*.id,
    var.security_group_ids,
  )

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  dynamic "block_device_mappings" {
    # Only create this block if any values are set within var.root_block_device
    for_each = var.root_block_device != {} ? { enabled = true } : {}

    content {
      device_name = lookup(var.root_block_device, "device_name", "/dev/xvda")

      ebs {
        volume_type           = lookup(var.root_block_device, "volume_type", null)
        volume_size           = lookup(var.root_block_device, "volume_size", null)
        iops                  = lookup(var.root_block_device, "iops", null)
        delete_on_termination = lookup(var.root_block_device, "delete_on_termination", null)
        encrypted             = lookup(var.root_block_device, "encrypted", null)
      }
    }
  }

  dynamic "credit_specification" {
    for_each = var.instance_cpu_credits != null ? { enabled = true } : {}
    content {
      cpu_credits = var.instance_cpu_credits
    }
  }
}

resource "aws_autoscaling_group" "instances" {
  name                = local.group_name
  vpc_zone_identifier = local.subnet_ids
  desired_capacity    = var.instances
  max_size            = var.instances
  min_size            = var.instances
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = aws_launch_template.instances.id
    version = "$Latest"
  }

  tag {
    key   = "Name"
    value = local.group_name
    propagate_at_launch = true
  }

  tag {
    key   = "Cluster"
    value = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key   = "Role"
    value = local.role_name
    propagate_at_launch = true
  }
}
