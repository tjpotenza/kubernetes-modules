# Module: `node_group`

---

Creates a group of nodes for running the majority of the workload.  Many different node groups can be associated with the same cluster.

## Example

```terraform
module "apollo_node_group" {
  source                = "../kubernetes-modules/node_group"
  cluster_name          = "apollo"
  k3s                  = {
    version = "v1.20.0+k3s2"
    options = [
      "--node-label", "variant=general"
    ]
  }
  instances             = 4
  vpc_tags              = { name = "default" }
  subnet_filters        = { availability-zone = ["us-east-1a"] }
  key_name              = "some_keypair"
  ami_regex             = "amzn2-ami-hvm-2.0.20201126.0-x86_64-gp2"
  root_block_device     = {
    volume_type = "gp3"
    volume_size = 50
  }

  security_group_ids   = module.apollo.security_group_ids
  target_group_arns    = module.apollo.target_group_arns
  instance_profile_arn = module.apollo.instance_profile_arn
}
```
