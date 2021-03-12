# Module: `shared_alb`

---

Manages an ALB and just the resources that'd be needed for a fairly typical use-case (namely listeners on ports `80`/`443` and security groups allowing connectivity into the ALB and between the ALB and any downstream instances).

## Example

```terraform
module "shared_external_alb" {
  source          = "../../kubernetes-modules/shared_alb"
  name            = "shared-external-alb"
  internal        = false
  vpc_tags        = { name = "default" }
  certificate_arn = module.shared_certificate.certificate_arn
}
```
