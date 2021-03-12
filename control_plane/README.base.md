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
