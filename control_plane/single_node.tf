resource "aws_instance" "single_node" {
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

  dynamic "credit_specification" {
    for_each = var.instance_cpu_credits != null ? {enabled = true} : {}
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
    local.external_control_plane_address != "" ? { ExternalAddress = local.external_control_plane_address } : {},
    local.internal_control_plane_address != "" ? { InternalAddress = local.internal_control_plane_address } : {}
  )
}

# Attaching the single node to our local ingress target groups
resource "aws_lb_target_group_attachment" "single_node_internal" {
  count            = !var.ha_enabled && local.internal_ingress_enabled ? 1 : 0
  target_group_arn = aws_lb_target_group.internal[0].arn
  target_id        = aws_instance.single_node[0].id
}

resource "aws_lb_target_group_attachment" "single_node_external" {
  count            = !var.ha_enabled && local.external_ingress_enabled ? 1 : 0
  target_group_arn = aws_lb_target_group.external[0].arn
  target_id        = aws_instance.single_node[0].id
}

# Attaching the single node to any shared ingress target groups
resource "aws_lb_target_group_attachment" "single_node_shared" {
  for_each          = !var.ha_enabled ? var.target_group_arns : {}
  target_group_arn  = each.value
  target_id         = aws_instance.single_node[0].id
}
