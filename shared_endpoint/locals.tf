locals {
  region   = data.aws_region.current.name
  endpoint = "${var.name}.${var.dns_zone}"
}
