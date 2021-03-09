resource "random_string" "target_group_nonce" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ingress" {
  for_each             = var.ingress
  name                 = substr("${random_string.target_group_nonce.result}-${var.cluster_name}-${each.key}", 0, 32)
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = local.vpc_id
  deregistration_delay = 60

  tags = {
    Cluster = var.cluster_name
    Type    = each.key
  }

  health_check {
    path = "/ping"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

# \/ These ugly for_each's exist because we need a target_group_attachment per instance, per target group

resource "aws_lb_target_group_attachment" "ingress" {
  for_each          = merge([
    for i in range(var.instances): {
      for ingress_type, ingress_config in var.ingress:
        "${i}-${ingress_type}" => { instance = aws_instance.instances[i], ingress_type = ingress_type, ingress_config = ingress_config }
        if contains(keys(ingress_config), "load_balancer")
    }
  ]...)
  target_group_arn = aws_lb_target_group.ingress[each.value.ingress_type].arn
  target_id        = each.value.instance.id
}

resource "aws_lb_target_group_attachment" "shared" {
  for_each          = merge([
    for i in range(var.instances): {
      for target_group_name, target_group_arn in var.target_group_arns:
        "${i}-${target_group_name}" => { instance = aws_instance.instances[i], target_group_arn = target_group_arn }
    }
  ]...)
  target_group_arn  = each.value
  target_id         = each.value.instance.id
}
