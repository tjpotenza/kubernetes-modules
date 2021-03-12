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

## Variable Reference
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | (Optional) The ID for the VPC within which resources will be created. | `string` | `null` |
| `subnet_ids` | (Optional) A list of subnets within which resources will be created. | `list` | `null` |
| `vpc_tags` | (Optional) A map of tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set. | `map` | `null` |
| `subnet_filters` | (Optional) A map of AWS filters to be use when looking up subnets.  Not used if subnet_ids is set. | `map` | `{}` |
| `security_group_names` | (Optional) A list of additional security groups by name which should be associated with each instance. | `list` | `[]` |
| `security_group_ids` | (Optional) A list of additional security groups by id which should be associated with each instance. | `list` | `[]` |
| `name` | (Required) A name for the ALB to be created. | `string` | `null` |
| `internal` | (Optional) Whether the ALB is internal or external. | `bool` | `false` |
| `certificate_arn` | (Required) The ARN of an existing ACM Certificate for use with TLS traffic. | `string` | `null` |
| `ingress_cidr_blocks` | (Optional) A list of ingress CIDRs from which traffic should be allowed into the load balancer. | `list` | `["0.0.0.0/0"]` |
| `egress_cidr_blocks` | (Optional) A list of egress CIDRs from which traffic should be allowed out of the load balancer. | `list` | `["0.0.0.0/0"]` |

## Output Reference
| Name | Description |
|------|-------------|
| `arn` | The ARN of the Application Load Balancer created by this module. |
| `dns_name` | The AWS-supplied DNS name of the Application Load Balancer created by this module. |
| `zone_id` | The AWS-supplied DNS Zone ID of the Application Load Balancer created by this module. |
| `security_group_ids` | A map of the Security Groups managed by this module.  Keys are 'upstream' and 'downstream', corresponding to the Security Groups that allows access into the load balancer and from the load balancer respectively. |
| `listener_arns` | A map where the keys are port numbers and the values are the ARNS to listeners on the created ALB for those ports.  Available keys are '443' and '80' currently. |

## Resources and Data Sources Used
* [aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) (resource)
* [aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) (resource)
* [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data)
* [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) (data)
* [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) (resource)
* [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) (data)
* [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) (data)

