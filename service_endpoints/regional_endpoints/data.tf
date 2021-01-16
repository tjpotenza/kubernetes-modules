data "aws_region" "current" {}

data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_route53_zone" "dns_zone" {
  name         = var.dns_zone
  private_zone = var.is_dns_zone_internal
}

data "aws_lb_listener" "shared_endpoint" {
  load_balancer_arn = var.alb_arns[local.region][var.shared_endpoint_type]
  port              = var.alb_port
}

data "aws_lb_listener" "cluster_endpoints" {
  load_balancer_arn = var.alb_arns[local.region][var.cluster_endpoints_type]
  port              = var.alb_port
}
