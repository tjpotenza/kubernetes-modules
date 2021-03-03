output "arn" {
  value = aws_lb.alb.arn
}

output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "zone_id" {
  value = aws_lb.alb.zone_id
}

output "upstream_sg_id" {
  value = aws_security_group.upstream.id
}

output "downstream_sg_id" {
  value = aws_security_group.downstream.id
}

output "listener_443_arn" {
  value = aws_lb_listener.ingress_443.arn
}
