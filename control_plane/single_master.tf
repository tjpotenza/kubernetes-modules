resource "aws_instance" "single_master" {
  count                  = var.ha_enabled ? 0 : 1
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = data.template_file.bootstrap_sh.rendered
  vpc_security_group_ids = concat(
    values(data.aws_security_group.instance).*.id,
    var.security_group_ids,
    [ aws_security_group.cluster_member.id ],
  )

  tags = merge(
    {
      Name    = "${var.cluster_name}-master"
      Cluster = var.cluster_name
      Role    = "control-plane"
    },
    local.control_plane_external_address_enabled ? { ExternalAddress = local.control_plane_external_address } : {},
    local.control_plane_internal_address_enabled ? { InternalAddress = local.control_plane_internal_address } : {}
  )
}

# Attaching the single master to our local ingress target group
resource "aws_lb_target_group_attachment" "single_master" {
  count            = var.ha_enabled ? 0 : 1
  target_group_arn = aws_lb_target_group.ingress.arn
  target_id        = aws_instance.single_master[0].id
}

# Attaching the single master to any shared ingress target groups
resource "aws_lb_target_group_attachment" "single_master_shared" {
  for_each          = var.ha_enabled ? {} : var.shared_target_group_arns
  target_group_arn  = each.value
  target_id         = aws_instance.single_master[0].id
}
