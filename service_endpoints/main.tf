locals {
  regions = distinct(concat(
    keys(var.alb_arns),
    keys(var.cluster_target_group_arns)
  ))

  us-east-1_enabled = contains(local.regions, "us-east-1")
  us-west-2_enabled = contains(local.regions, "us-west-2")
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

################################################################################
# Actually Invoking the Module Itself, but in each Region
#
#   This is a janky hack and I hate it, but is the best approach to pulling off
#   what I had in mind.  I *think* that it is currently impossible for providers
#   to be assigned dynamically in something like a for_each, so there'd need to
#   be *some* duplication somewhere.  The submodule accepts the same variables
#  as this one, so this just passes all the variables through while setting a
#  different provider for each supported region.  These invocations should all
#  be identical outside the providers and count lines.
################################################################################
module "us-east-1" {
  providers = { aws = aws.us-east-1 }
  count     = local.us-east-1_enabled ? 1 : 0

  source                          = "./regional_endpoints"
  vpc_name                        = var.vpc_name
  dns_zone                        = var.dns_zone
  is_dns_zone_internal            = var.is_dns_zone_internal
  name                            = var.name
  alb_arns                        = var.alb_arns
  alb_port                        = var.alb_port
  dns_records_enabled             = var.dns_records_enabled
  cluster_target_group_arns       = var.cluster_target_group_arns
  target_port                     = var.target_port
  healthcheck_path                = var.healthcheck_path
  shared_endpoint_type            = var.shared_endpoint_type
  shared_endpoint_ingress_cidrs   = var.shared_endpoint_ingress_cidrs
  shared_endpoint_dns_regions     = var.shared_endpoint_dns_regions
  shared_endpoint_clusters        = var.shared_endpoint_clusters
  cluster_endpoints_type          = var.cluster_endpoints_type
  cluster_endpoints_ingress_cidrs = var.cluster_endpoints_ingress_cidrs
  cluster_endpoints_clusters      = var.cluster_endpoints_clusters
}

module "us-west-2" {
  providers = { aws = aws.us-west-2 }
  count     = local.us-west-2_enabled ? 1 : 0

  source                          = "./regional_endpoints"
  vpc_name                        = var.vpc_name
  dns_zone                        = var.dns_zone
  is_dns_zone_internal            = var.is_dns_zone_internal
  name                            = var.name
  alb_arns                        = var.alb_arns
  alb_port                        = var.alb_port
  dns_records_enabled             = var.dns_records_enabled
  cluster_target_group_arns       = var.cluster_target_group_arns
  target_port                     = var.target_port
  healthcheck_path                = var.healthcheck_path
  shared_endpoint_type            = var.shared_endpoint_type
  shared_endpoint_ingress_cidrs   = var.shared_endpoint_ingress_cidrs
  shared_endpoint_dns_regions     = var.shared_endpoint_dns_regions
  shared_endpoint_clusters        = var.shared_endpoint_clusters
  cluster_endpoints_type          = var.cluster_endpoints_type
  cluster_endpoints_ingress_cidrs = var.cluster_endpoints_ingress_cidrs
  cluster_endpoints_clusters      = var.cluster_endpoints_clusters
}
