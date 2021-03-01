# Record for Public Control Plane API endpoint
resource "aws_route53_record" "external_control_plane" {
  count   = local.external_control_plane_address != "" ? 1 : 0

  zone_id = data.aws_route53_zone.external[0].zone_id
  name    = local.external_control_plane_address
  type    = "A"
  records = aws_instance.single_node[*].public_ip
  ttl     = 60
}

# Record for Public Control Plane API endpoint
resource "aws_route53_record" "internal_control_plane" {
  count   = local.internal_control_plane_address != "" ? 1 : 0

  zone_id = data.aws_route53_zone.internal[0].zone_id
  name    = local.internal_control_plane_address
  type    = "A"
  records = aws_instance.single_node[*].private_ip
  ttl     = 60
}
