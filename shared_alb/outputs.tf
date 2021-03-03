output "arn" {
  value = aws_lb.alb.arn
}

output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "zone_id" {
  value = aws_lb.alb.zone_id
}

output "security_group_ids" {
  value = {
    upstream   = aws_security_group.upstream.id
    downstream = aws_security_group.downstream.id
  }
}

output "listener_arns" {
  value = {
    "443" = aws_lb_listener.ingress_443.arn
  }
}
