variable "vpc_name" {
  default     = "Name for the VPC within which everything should be created."
  type        = string
}

variable "dns_zone" {
  description = "(Optional) Name for the DNS zone within which service records should be created.  Required unless dns_record_enabled == false."
  type        = string
}

variable "is_dns_zone_internal" {
  description = "(Optional) Whether or not the DNS zone for this service is internal or external."
  type        = bool
  default     = false
}

variable "name" {
  description = "(Required) Name of the service for which this module routes."
  type        = string
}

variable "alb_arn" {
  description = "(Optional) ARN of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_name is not set."
  type        = string
  default     = null
}

variable "alb_name" {
  description = "(Optional) Unique name of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_arn is not set."
  type        = string
  default     = null
}

variable "alb_port" {
  description = "(Optional) Port of the ALB Listener for which the service's rules should be associated."
  type        = number
  default     = 443
}

variable "dns_record_enabled" {
  description = "(Optional) Whether or not the DNS record should be created for this service."
  type        = bool
  default     = true
}

variable "target_port" {
  description = "(Optional) Port on the instances to which traffic and healthchecks should be routed."
  type        = number
  default     = 80
}

variable "healthcheck_path" {
  description = "(Optional) Path of the healthcheck to determine whether instance is routable."
  type        = string
  default     = "/ping"
}

variable "target_group_arns" {
  description = "(Optional) Map of cluster names that should be routable for this service, and the ARN of their ingress target group."
  type        = map(string)
  default     = {}
}

variable "weights" {
  description = "(Optional) Map of cluster names if they should have special weighting applied.  Any clusters not included in this map will receive a weight of 1."
  type        = map(number)
  default     = {}
}

variable "restricted_cidrs" {
  description = "List of CIDRs that should be permitted to access 'restricted' hostnames and services on the cluster.  No source IP restrictions will be created if empty."
  type        = list
  default     = []
}

variable "stickiness_enabled" {
  description = "(Optional) Indicates whether target group stickiness is enabled."
  type        = bool
  default     = false
}

variable "stickiness_duration" {
  description = "(Optional) The time period, in seconds, during which requests from a client should be routed to the same target group. The range is 1-604800 seconds (7 days)."
  type        = number
  default     = 30
}
