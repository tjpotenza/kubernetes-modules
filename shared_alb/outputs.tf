output "arn" {
  description = "The ARN of the Application Load Balancer created by this module."
  value       = aws_lb.alb.arn
}

output "dns_name" {
  description = "The AWS-supplied DNS name of the Application Load Balancer created by this module."
  value       = aws_lb.alb.dns_name
}

output "zone_id" {
  description = "The AWS-supplied DNS Zone ID of the Application Load Balancer created by this module."
  value       = aws_lb.alb.zone_id
}

output "security_group_ids" {
  description = "A map of the Security Groups managed by this module.  Keys are 'upstream' and 'downstream', corresponding to the Security Groups that allows access into the load balancer and from the load balancer respectively."
  value       = {
    upstream   = aws_security_group.upstream.id
    downstream = aws_security_group.downstream.id
  }
}

output "listener_arns" {
  description = "A map where the keys are port numbers and the values are the ARNS to listeners on the created ALB for those ports.  Available keys are '443' and '80' currently."
  value       = {
    "443" = aws_lb_listener.ingress_443.arn
    "80"  = aws_lb_listener.ingress_80.arn
  }
}
