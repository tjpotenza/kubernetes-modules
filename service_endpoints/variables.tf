variable "vpc_name" {
  default     = "Name for the VPC within which everything should be created."
  type        = string
}

variable "dns_zone" {
  description = "Name for the DNS zone within which service records should be created."
  type        = string
}

variable "is_dns_zone_internal" {
  description = "Whether or not the DNS zone for this service is internal or external."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the service for which this module routes."
  type        = string
}

variable "alb_arns" {
  description = "Nested map that allows the ARN of an external ALB and an internal ALB to be included per-region."
  type        = map
  default     = {}
}

variable "alb_port" {
  description = "Port on the ALB rules for which the service's rules should be associated."
  type        = number
  default     = 443
}

variable "dns_records_enabled" {
  description = "Whether or not the DNS records should be created for this service."
  type        = bool
  default     = true
}

variable "cluster_target_group_arns" {
  description = "Nested Map where the target group for each cluster can get associated with a name and a region."
  type        = map
  default     = {}
}

variable "target_port" {
  description = "Port on the instances to which traffic and healthchecks should be routed."
  type        = number
  default     = 80
}

variable "healthcheck_path" {
  description = "Path of the healthcheck to determine whether instance is routable."
  type        = string
  default     = "/ping"
}


variable "shared_endpoint_type" {
  description = "The type of alb that should be associated with the shared endpoint."
  type        = string
  default     = "external"
}

variable "shared_endpoint_ingress_cidrs" {
  description = "List of CIDRs from which to restrict access for the shared endpoint.  Defaults to the endpoints being unrestricted if not specified."
  type        = list
  default     = []
}

variable "shared_endpoint_dns_regions" {
  description = "List of regions for which DNS records should be created.  Mostly exists to allow a region to be removed from rotation before removing ALB rules, to give wiggle room for DNS ttls."
  type        = list
  default     = []
}

variable "shared_endpoint_clusters" {
  description = "Map with region slug as the key and a list of clusters who should be associated with that regions ALB for the shared endpoint as the value."
  type        = map
  default     = {}
}

variable "cluster_endpoints_type" {
  description = "The type of alb that should be associated with the cluster endpoints."
  type        = string
  default     = "external"
}

variable "cluster_endpoints_ingress_cidrs" {
  description = "List of CIDRs from which to restrict access for cluster endpoints.  Defaults to the endpoints being unrestricted if not specified."
  type        = list
  default     = []
}

variable "cluster_endpoints_clusters" {
  description = "Map with region slug as the key and a list of clusters who should be associated with that regions ALB for cluster endpoints as the value."
  type        = map
  default     = {}
}
