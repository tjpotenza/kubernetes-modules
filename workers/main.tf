locals {
  master_address     = "master--${var.cluster_name}.${var.dns_zone}"
  node_token_address = "node-token--${var.cluster_name}.${var.dns_zone}"
}

resource "aws_launch_template" "workers" {
  name_prefix            = "${var.cluster_name}-worker"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = base64encode(templatefile("${path.module}/bootstrap.sh", {
    master_address     = local.master_address
    node_token_address = local.node_token_address
  }))
  vpc_security_group_ids = concat(
    values(data.aws_security_group.instance).*.id,
    var.security_group_ids
  )
}

resource "aws_autoscaling_group" "workers" {
  name                = "${var.cluster_name}-workers"
  vpc_zone_identifier = data.aws_subnet_ids.main.ids
  desired_capacity    = var.instances
  max_size            = var.instances
  min_size            = var.instances

  launch_template {
    id      = aws_launch_template.workers.id
    version = "$Latest"
  }

  tag {
    key   = "Name"
    value = "${var.cluster_name}-worker"
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
