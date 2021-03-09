# Since it's kinda tough to auto-pick subnet groups in a way that's both intuitive *and* won't heavily favor
# the same exact distribution in different projects, we just sort the list and generate a random offset
# at which to start iterating.  Technically we'll still trend toward groups of the same lexicographically
# sequential sets of subnets across projects, but that's good enough for my use cases (for now).
resource "random_integer" "subnet_offset" {
  min = 0
  max = 255
}

resource "aws_instance" "instances" {
  count                  = var.instances
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data_base64       = data.template_cloudinit_config.user_data.rendered
  iam_instance_profile   = aws_iam_instance_profile.control_plane.id
  subnet_id              = (
    length(local.subnet_ids) == 0 ? null :
      element(local.subnet_ids, random_integer.subnet_offset.result + count.index)
  )
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
