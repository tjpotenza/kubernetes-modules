# Record for Public Control Plane API endpoint
resource "aws_route53_record" "api_server_external" {
  count   = 1
  zone_id = data.aws_route53_zone.ingress.zone_id
  name    = local.master_address
  type    = "A"
  records = aws_instance.single_master[*].public_ip
  ttl     = 60
}

# Record for Public Control Plane API endpoint
resource "aws_route53_record" "api_server_internal" {
  count   = 1
  zone_id = data.aws_route53_zone.ingress_internal.zone_id
  name    = local.master_address
  type    = "A"
  records = aws_instance.single_master[*].private_ip
  ttl     = 60
}
