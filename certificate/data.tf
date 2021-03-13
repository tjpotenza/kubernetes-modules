data "aws_route53_zone" "domain_name" {
  count        = var.validation_zone_id == null ? 1 : 0
  name         = var.domain_name
  private_zone = false # DNS-based validation doesn't work for private zones, so no point making this configurable
}

locals {
  validation_zone_id = var.validation_zone_id == null ? data.aws_route53_zone.domain_name[0].zone_id : var.validation_zone_id
}
