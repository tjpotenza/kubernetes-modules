output "certificate_arn" {
  description = "The ARN of the created certificate."
  value       = aws_acm_certificate_validation.certificate_validation.certificate_arn
}
