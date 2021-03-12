# Module: `node_group`

---

Creates a group of control plane instances.  Many different control plane instance groups can be associated with the same cluster.

## Example

```terraform
module "apollo" {
  source               = "../kubernetes-modules/control_plane"
  cluster_name         = "apollo"
  instances            = 1
  k3s                  = {
    version  = "v1.20.4+k3s1"
  }
  vpc_tags             = { name = "default" }
  key_name             = "some_keypair"
  ami_regex            = "amzn2-ami-hvm-2.0.20201126.0-x86_64-gp2"
  instance_type        = "t3a.small"
  instance_cpu_credits = "standard"
  root_block_device    = {
    volume_type = "gp3"
    volume_size = 50
  }

  security_group_ids   = module.apollo.security_group_ids
  target_group_arns    = module.apollo.target_group_arns
  instance_profile_arn = module.apollo.instance_profile_arn
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
| `instances` | (Optional) The number of instances to be created in this group. | `number` | `1` |
| `instance_type` | (Optional) The AWS instance type to use for new instances. | `string` | `t2.micro` |
| `instance_cpu_credits` | (Optional) The credit option for CPU usage. Can be 'standard' or 'unlimited'. T3 instances are launched as unlimited by default. T2 instances are launched as standard by default. | `string` | `null` |
| `key_name` | (Optional) Name for the SSH keypair to associate with each instance. | `string` | `null` |
| `ami_regex` | (Required) A regular expression to use when looking up the AMI by name to use for each instance. | `string` | `null` |
| `root_block_device` | (Optional) A map of the values for configuring an instance's root block device.  Supported options are [ volume_type, volume_size, iops, delete_on_termination, encrypted ]. | `map` | `{}` |
| `instance_profile_arn` | (Required) The ARN for an IAM Instance Profile to associate with instances. | `string` | `null` |
| `k3s` | (Optional) Options for configuring installation of k3s. | `map` | `{}` |
| `etcd` | (Optional) Options for configuring the installation of etcd. | `map` | `{}` |
| `control_plane_sans` | (Optional) Additional Subject Alternative Name records to include in the API Server certificate. | `list` | `[]` |

## Output Reference
| Name | Description |
|------|-------------|


## Resources and Data Sources Used
* [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) (data)
* [aws_autoscaling_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) (resource)
* [aws_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) (resource)
* [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data)
* [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) (data)
* [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) (data)
* [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) (data)
* [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
* [template_cloudinit_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) (data)

