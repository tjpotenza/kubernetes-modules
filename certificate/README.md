# Module: `certificate`

---

Creates an ACM certificate and validates it with DNS-based validation.

## Example

```terraform
data "aws_region" "current" {}

module "shared_certificate" {
  source   = "../../kubernetes-modules/certificate"
  name                      = "shared-certificate"
  domain_name               = "example.com"
  subject_alternative_names = [
    "*.example.com",
    "*.internal.example.com",
    "*.${data.aws_region.current.name}.example.com",
    "*.${data.aws_region.current.name}.internal.example.com",
  ]
}
```

## Variable Reference
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | (Required) A name to associate with the certificate. | `string` | `null` |
| `domain_name` | (Required) The primary domain name to associate with the certificate. | `string` | `null` |
| `validation_zone_id` | (Optional) ID of the Route53 zone in which the records should be created for DNS-based certificate validation, if it can't be determined just by a data lookup of var.domain_name. | `string` | `null` |
| `subject_alternative_names` | (Optional) Additional Subject Alternative Names to associate with the certificate. | `list` | `[]` |
| `validation_zone_id_overrides` | (Optional) A map where each key is one of the subject alternative names and each value is the Route53 Zone ID to use for DNS-based ACM validation.  Only needed for SANs that reside within a different Route53 zone than the one in validation_zone_id. | `map` | `{}` |

## Output Reference
| Name | Description |
|------|-------------|
| `certificate_arn` | The ARN of the created certificate. |

## Resources and Data Sources Used
* [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) (resource)
* [aws_acm_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) (resource)
* [aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) (resource)
* [aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) (data)

