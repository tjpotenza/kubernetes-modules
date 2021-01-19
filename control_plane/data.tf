data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_route53_zone" "external" {
  count = local.control_plane_external_address_enabled ? 1 : 0
  name  = var.external_dns_zone
}

data "aws_route53_zone" "internal" {
  count        = local.control_plane_internal_address_enabled ? 1 : 0
  name         = var.internal_dns_zone
  private_zone = true
}

data "aws_ami" "ami" {
  name_regex  = var.ami_regex
  owners      = ["amazon"]
  most_recent = true
}

data "aws_security_group" "instance" {
  for_each = toset(var.security_group_names)
  name     = each.value
}
