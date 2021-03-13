# Target Group names are forever a pain to manage.  `name_prefix` only supports something like 6 characters,
# names have a length limit of 32 characters, and they must be unique.  Names can be omitted altogether in
# favor of random IDs, however those make it difficult to read ALB configurations in the AWS Console; it's
# several clicks between a particular ALB rule and figuring out exactly which target groups are downstream.
#
# Target groups can also be attached many times to an ALB, but can only be attached to on particular ALB
# at time; basically meaning we need to create one for each ALB that'll be associated with this cluster,
# and ensure that their names are all unique from each other and from their replacements if recreated.
#
# This compromises and settles on "ugly but somewhat significant and definitely unique names".  (We truncate
# before adding the nonce suffix so a cluster with a long name can't displace the unique value entirely.)
resource "random_string" "target_group_nonce" {
  for_each = var.cluster_target_groups
  length  = 6
  upper   = false
  special = false
  keepers = {
    cluster_name = var.cluster_name
  }
}

resource "aws_lb_target_group" "cluster_target_groups" {
  for_each             = var.cluster_target_groups
  name                 = "${ substr("${var.cluster_name}-${each.key}", 0, 25) }-${ random_string.target_group_nonce[each.key].result }"
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
