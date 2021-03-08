resource "aws_route53_record" "ingress" {
  for_each = {
    for name, config in var.ingress:
      name => config if contains(keys(config), "dns_zone")
  }
  zone_id  = data.aws_route53_zone.ingress[each.key].zone_id
  name     = "control-plane--${var.cluster_name}.${local.region}.${each.value.dns_zone}"
  type     = "A"
  ttl      = 60
  records  = (
    lookup(each.value, "internal", false) ? concat(
      aws_instance.single_node[*].private_ip,
      aws_instance.ha_nodes[*].private_ip,
    ) : concat(
      aws_instance.single_node[*].public_ip,
      aws_instance.ha_nodes[*].public_ip,
    )
  )
}
