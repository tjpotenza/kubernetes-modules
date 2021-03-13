data "aws_region" "current" {}

data "aws_vpc" "main" {
  count = (var.vpc_id == null ? 1 : 0)
  tags  = var.vpc_tags
}

data "aws_subnet_ids" "main" {
  count  = (var.subnet_ids == null ? 1 : 0)
  vpc_id = local.vpc_id

  dynamic "filter" {
    for_each = var.subnet_filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_security_group" "from_names" {
  for_each = toset(var.security_group_names)
  name     = each.value
}
