# The cert itself
resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.name != null ? {
    Name = var.name
  } : {}
}

# Unique records created in each zone attached to the cert so AWS can validate we own 'em
resource "aws_route53_record" "certificate_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = lookup(
        var.validation_zone_id_overrides,
        dvo.domain_name,
        var.validation_zone_id
      )
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

# The actual process to validate we own the domains associated with the cert
resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation_records : record.fqdn]
}

# Reference certs with the output from the validation resource so the dependency graph will treat it as a dependency
# aws_acm_certificate_validation.certificate_validation.certificate_arn
