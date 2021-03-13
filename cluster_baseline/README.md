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

## Variable Reference
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | (Optional) The ID for the VPC within which resources will be created. | `string` | `null` |
| `subnet_ids` | (Optional) A list of subnets within which resources will be created. | `list` | `null` |
| `vpc_tags` | (Optional) A map of tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set. | `map` | `null` |
| `subnet_filters` | (Optional) A map of AWS filters to be use when looking up subnets.  Not used if subnet_ids is set. | `map` | `{}` |
| `security_group_names` | (Optional) A list of additional security groups by name which should be associated with each instance. | `list` | `[]` |
| `security_group_ids` | (Optional) A list of additional security groups by id which should be associated with each instance. | `list` | `[]` |
| `target_group_arns` | (Optional) A list of ARNs for target groups that should be associated with cluster instances. | `list` | `[]` |
| `target_group_names` | (Optional) A list of names for target groups that should be associated with cluster instances. | `list` | `[]` |
| `cluster_name` | (Required) A unique name or identifier for the cluster. | `string` | `null` |
| `cluster_target_groups` | (Optional) A map of target groups to create for this cluster, where a target group will be created for each key. | `map` | `{}` |

## Output Reference
| Name | Description |
|------|-------------|
| `target_group_arns` | A list of ARNs for all Target Groups either created by or passed into this module. |
| `instance_profile_arn` | The ARN of the Instance Profile created by this module. |
| `security_group_ids` | A list of ARNs for all Security Groups either created by or passed into this module. |
| `cluster_target_groups` | A map containing references to the Target Groups managed by this module, with keys matching the input variable of the same name. |

## Resources and Data Sources Used
* [aws_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) (resource)
* [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) (resource)
* [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
* [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
* [aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) (data)
* [aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) (data)
* [aws_lb_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) (resource)
* [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_target_group) (data)
* [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) (resource)
* [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data)
* [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) (data)
* [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) (resource)
* [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) (data)
* [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) (data)
* [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)

