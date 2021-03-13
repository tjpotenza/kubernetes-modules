# Example Module Invocations

Below is one way these modules can be invoked to create:
* A bunch of infrastructure dependencies that can be shared across several clusters within a particular region.
* A cluster (named `apollo`) with two variants of nodes.
* A shared endpoint for `nginx.example.com` that routes to our new cluster.

_Note: Values are defined in-line for purposes of keeping the examples concise and readable; actually `terraform apply`-ing resources based off of this config will need values such as `dns_zone`, `vpc_tags`, `key_name`._

_Note: This example also presumes that the `Shared Resources` are managed separately from any clusters, and would be fully bootstrapped before clusters are built.  To deploy them in the same run as a cluster, `cluster_baseline`'s inputs for `security_group_names` and `cluster_target_groups.external.lb_listener_rule.lb_name` should be replaced with `security_group_ids` and `...lb_arn` inputs that directly reference outputs from `shared_alb` and `aws_security_group`._

## Building Shared Resources for a Region
```terraform
locals {
    restricted_cidrs = [] # List of CIDRs that should be able to directly reach cluster members
}

data "aws_region" "current" {}
data "aws_vpc"    "main"    { tags = {} }

module "shared_certificate" {
  source                    = "../../kubernetes-modules/certificate"
  name                      = "shared-certificate"
  domain_name               = local.dns_zone
  subject_alternative_names = [
    "*.example.com",
    "*.internal.example.com",
    "*.${data.aws_region.current.name}.example.com",
    "*.${data.aws_region.current.name}.internal.example.com",
    # You can't normally use DNS-based validation for SANs in private zones, but you can
    # cheat and validate those SANs against a public zone if the records have names that
    # are valid in either zones (ie example.com and internal.example.com).
  ]
}

module "shared_external_alb" {
  source          = "../../kubernetes-modules/shared_alb"
  name            = "shared-external-alb"
  internal        = false
  vpc_tags        = { name = "default" }
  certificate_arn = module.shared_certificate.certificate_arn
}

resource "aws_security_group" "ingress_instance_restricted" {
  name        = "ingress-instance-restricted"
  vpc_id      = data.aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.restricted_cidrs
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.restricted_cidrs
  }
}

resource "aws_security_group" "egress_all" {
  name        = "egress-all"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Building a Cluster: Apollo

```terraform
locals {
    restricted_cidrs = [] # List of CIDRs that should be able to reach the auto-ingress endpoint
}

module "apollo" {
  source                = "../kubernetes-modules/cluster_baseline"
  cluster_name          = "apollo"
  vpc_tags              = { name = "default" }
  security_group_names  = [ "ingress-instance-restricted", "egress-all", "shared-external-alb-downstream" ]
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

module "apollo_control_plane" {
  source               = "../kubernetes-modules/control_plane"
  cluster_name         = "apollo"
  instances            = 1
  k3s                  = {
    version  = "v1.20.4+k3s1"
  }
  vpc_tags             = { name = "default" }
  key_name             = "some-key-pair"
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

module "apollo_node_group" {
  source                = "../kubernetes-modules/node_group"
  cluster_name          = "apollo"
  k3s                  = {
    version  = "v1.20.0+k3s2"
  }
  instances             = 1
  vpc_tags              = { name = "default" }
  key_name              = "some-key-pair"
  ami_regex             = "amzn2-ami-hvm-2.0.20201126.0-x86_64-gp2"
  root_block_device     = {
    volume_type = "gp3"
    volume_size = 50
  }

  security_group_ids   = module.apollo.security_group_ids
  target_group_arns    = module.apollo.target_group_arns
  instance_profile_arn = module.apollo.instance_profile_arn
}

module "apollo_node_group_reserved" {
  source                = "../kubernetes-modules/node_group"
  cluster_name          = "apollo"
  k3s                  = {
    version  = "v1.20.0+k3s2"
    options = [
      "--node-label", "variant=reserved"
    ]
  }
  instances             = 1
  vpc_tags              = { name = "default" }
  subnet_filters        = { availability-zone = ["us-east-1a"] }
  key_name              = "some-key-pair"
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

## Building a Shared Service Endpoint: Blog
```terraform
# blog.example.com
module "blog_us-east-1" {
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
