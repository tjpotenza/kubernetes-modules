# Module: `shared_endpoint`

---

Creates a DNS record and ALB Listener Rule for a service that can route requests across one or more clusters.  Records are created with latency-based routing by default, allowing support for services deployed across multiple regions.  Can accept and attach to a set of existing `Target Groups` or create a service-specific `Target Group` that can be attached to clusters.

## Example

```terraform
module "blog_use1" {
  source            = "../kubernetes-modules/shared_endpoint"
  vpc_tags          = { name = "default" }
  alb_name          = "shared-external-alb"
  name              = "blog"
  dns_zone          = "example.com"
  target_group_arns = {
    apollo = module.apollo.cluster_target_groups["external"].arn
  }
}
```
