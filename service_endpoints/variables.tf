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
  description = "Map that allows the ARN of an external ALB and an internal ALB to be specified, for selection in shared_endpoint and cluster_endpoints."
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

variable "shared_endpoint" {
  description = ""
  default     = {}
}

variable "cluster_endpoints" {
  description = ""
  default     = {}
}