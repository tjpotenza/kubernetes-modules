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
