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

## Variables
* **alb_arn**: (Optional) The ARN of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_name is not set. _(type: string, default: null)_
* **alb_name**: (Optional) A unique name of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_arn is not set. _(type: string, default: null)_
* **alb_port**: (Optional) The port of the ALB Listener for which the service's rules should be associated. _(type: number, default: 443)_
* **dns_record_enabled**: (Optional) Whether or not the DNS record should be created for this service. _(type: bool, default: true)_
* **dns_zone**: (Optional) A name for the DNS zone within which service records should be created. _(type: string, default: null)_
* **dns_zone_id**: (Optional) The ID of the DNS zone within which service records should be created. _(type: string, default: null)_
* **healthcheck_path**: (Optional) The path of the healthcheck to determine whether instance is routable. _(type: string, default: /ping)_
* **is_dns_zone_internal**: (Optional) Whether or not the DNS zone for this service is internal or external. _(type: bool, default: false)_
* **name**: (Required) The name of the service for which this module routes. _(type: string, default: null)_
* **restricted_cidrs**: (Optional) If not empty, the ALB will set a source_ip condition to restrict access to only this list of CIDRs.  No source IP restrictions will be created if empty.  ALBs only allow a small handful of conditions, so this should only be used with 3-4 CIDRs; for any more create a new ALB and restrict access at the security group level. _(type: list, default: [])_
* **shared_target_group**: (Optional) Whether to enable the creation of a shared Target Group, and settings to assign it.  See locals.tf for options and defaults. _(type: map, default: {})_
* **stickiness_duration**: (Optional) The time period, in seconds, during which requests from a client should be routed to the same target group. The range is 1-604800 seconds (7 days). _(type: number, default: 30)_
* **stickiness_enabled**: (Optional) Whether target group stickiness is enabled. _(type: bool, default: false)_
* **target_group_arns**: (Optional) A map of cluster names that should be routable for this service, and the ARN of their ingress target group. _(type: map(string), default: {})_
* **target_port**: (Optional) The port on the instances to which traffic and healthchecks should be routed. _(type: number, default: 80)_
* **vpc_id**: (Optional) The ID for the VPC within which resources will be created. _(type: string, default: null)_
* **vpc_tags**: (Optional) A map of tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set. _(type: map, default: null)_
* **weights**: (Optional) A map of cluster names if they should have special weighting applied.  Any clusters not included in this map will receive a weight of 1. _(type: map(number), default: {})_

## Outputs
* **shared_target_group_arn**: ARN of the shared target group, if one was created. _(type: any, default: n/a)_

## Resources Used
* [object](https://registry.terraform.io/providers/null/null/docs/resources/null)
