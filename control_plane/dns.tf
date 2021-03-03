resource "aws_route53_record" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "dns_zone")
  }
  zone_id  = data.aws_route53_zone.ingress[each.key].zone_id
  name     = "control-plane--${var.cluster_name}.${local.region}.${each.value.dns_zone}"
  type     = "A"
  records  = lookup(each.value, "internal", false) ? aws_instance.single_node[*].private_ip : aws_instance.single_node[*].public_ip
  ttl      = 60
}
