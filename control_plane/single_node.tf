resource "aws_instance" "single_node" {
  count                  = var.ha_enabled ? 0 : 1
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data_base64       = data.template_cloudinit_config.user_data.rendered
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

resource "aws_lb_target_group_attachment" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "load_balancer") && !var.ha_enabled
  }
  target_group_arn = aws_lb_target_group.ingress[each.key].arn
  target_id        = aws_instance.single_node[0].id
}

# Attaching the single node to any shared ingress target groups
resource "aws_lb_target_group_attachment" "single_node_shared" {
  for_each          = !var.ha_enabled ? var.target_group_arns : {}
  target_group_arn  = each.value
  target_id         = aws_instance.single_node[0].id
}
