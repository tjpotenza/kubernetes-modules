# Module: `cluster_baseline`

---

Creates most of the auxiliary resources for a cluster such as target groups, IAM roles, security groups, and ALB listener rules.  Target Groups and Security Groups passed into this module will be passed through and into the module outputs, so any that should be associated with all instances and autoscaling groups for the cluster can be added once here.

## Example

```terraform
module "apollo" {
  source                = "../kubernetes-modules/cluster_baseline"
  cluster_name          = "apollo"
  vpc_tags              = { name = "default" }
  subnet_filters        = { availability-zone = ["us-east-1a"] }
  security_group_names  = [ "egress-all", "ingress-private", "shared-external-alb-downstream" ]
  cluster_target_groups = {
    external = {
      lb_listener_rule = {
        lb_name          = "shared-external-alb"
        dns_zone         = "example.com"
        restricted_cidrs = local.restricted_cidrs
      }
    }
  }
}
```
