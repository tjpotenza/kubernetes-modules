# `shared_endpoint`

---

Creates a DNS record and ALB Listener Rule for a service that can route requests across one or more clusters.

## Example

```terraform
module "nginx_use1" {
  source            = "../kubernetes-modules/shared_endpoint"
  vpc_tags          = { name = "default" }
  alb_name          = "shared-external-alb"
  name              = "nginx"
  dns_zone          = "example.com"
  target_group_arns = {
    apollo = module.apollo.cluster_target_groups["external"].arn
  }
}
```
