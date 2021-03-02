resource "aws_launch_template" "workers" {
  name_prefix            = "${var.cluster_name}-worker"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = base64encode(data.template_file.bootstrap_sh.rendered)
  # user_data              = base64encode(templatefile("${path.module}/bootstrap.sh", {
  #   control_plane_address = local.internal_control_plane_address
  #   k3s_install_options   = local.k3s_install_options
  # }))
  vpc_security_group_ids = concat(
    values(data.aws_security_group.instance).*.id,
    var.security_group_ids
  )

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
}

resource "aws_autoscaling_group" "workers" {
  name                = "${var.cluster_name}-workers"
  vpc_zone_identifier = data.aws_subnet_ids.main.ids
  desired_capacity    = var.instances
  max_size            = var.instances
  min_size            = var.instances
  target_group_arns   = values(var.target_group_arns)

  launch_template {
    id      = aws_launch_template.workers.id
    version = "$Latest"
  }

  tag {
    key   = "Name"
    value = "${var.cluster_name}-workers"
    propagate_at_launch = true
  }

  tag {
    key   = "Cluster"
    value = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key   = "Role"
    value = "worker"
    propagate_at_launch = true
  }
}
