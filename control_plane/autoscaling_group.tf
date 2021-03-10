resource "aws_launch_template" "control_plane" {
  name_prefix            = "${var.cluster_name}-control-plane"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = data.template_cloudinit_config.user_data.rendered
  vpc_security_group_ids = concat(
    values(data.aws_security_group.instance).*.id,
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

resource "aws_autoscaling_group" "control_plane" {
  name                = "${var.cluster_name}-control-plane"
  vpc_zone_identifier = local.subnet_ids
  desired_capacity    = var.instances
  max_size            = var.instances
  min_size            = var.instances
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = aws_launch_template.control_plane.id
    version = "$Latest"
  }

  tag {
    key   = "Name"
    value = "${var.cluster_name}-control-plane"
    propagate_at_launch = true
  }

  tag {
    key   = "Cluster"
    value = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key   = "Role"
    value = "control-plane"
    propagate_at_launch = true
  }
}
