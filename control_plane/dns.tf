# Record for Public Control Plane API endpoint
resource "aws_route53_record" "control_plane_external" {
  count   = local.control_plane_external_address_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.external[0].zone_id
  name    = local.control_plane_external_address
  type    = "A"
  records = aws_instance.single_master[*].public_ip
  ttl     = 60
}

# Record for Public Control Plane API endpoint
resource "aws_route53_record" "control_plane_internal" {
  count   = local.control_plane_internal_address_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.internal[0].zone_id
  name    = local.control_plane_internal_address
  type    = "A"
  records = aws_instance.single_master[*].private_ip
  ttl     = 60
}
