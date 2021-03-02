data "aws_region" "current" {}

data "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0
  tags  = var.vpc_tags
}

locals {
  vpc_id = (var.vpc_id == null ? data.aws_vpc.main[0].id : var.vpc_id)
}

data "aws_route53_zone" "dns_zone" {
  count        = var.dns_record_enabled ? 1 : 0
  name         = var.dns_zone
  private_zone = var.is_dns_zone_internal
}

data "aws_lb" "shared_endpoint" {
  name = var.alb_name
  arn  = var.alb_arn
}

data "aws_lb_listener" "shared_endpoint" {
  load_balancer_arn = data.aws_lb.shared_endpoint.arn
  port              = var.alb_port
}
