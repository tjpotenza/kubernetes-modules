variable "vpc_id" {
  description = "(Optional) The ID for the VPC within which resources will be created."
  type        = string
  default     = null
}

variable "vpc_tags" {
  description = "(Optional) A map of tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set."
  type        = map
  default     = null
}

variable "dns_zone" {
  description = "(Optional) A name for the DNS zone within which service records should be created.  Required unless dns_record_enabled == false."
  type        = string
}

variable "is_dns_zone_internal" {
  description = "(Optional) Whether or not the DNS zone for this service is internal or external."
  type        = bool
  default     = false
}

variable "name" {
  description = "(Required) The name of the service for which this module routes."
  type        = string
}

variable "alb_arn" {
  description = "(Optional) The ARN of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_name is not set."
  type        = string
  default     = null
}

variable "alb_name" {
  description = "(Optional) A unique name of the ALB the Route53 Records will point to, and for which the rules will be created.  Required if alb_arn is not set."
  type        = string
  default     = null
}

variable "alb_port" {
  description = "(Optional) The port of the ALB Listener for which the service's rules should be associated."
  type        = number
  default     = 443
}

variable "dns_record_enabled" {
  description = "(Optional) Whether or not the DNS record should be created for this service."
  type        = bool
  default     = true
}

variable "target_port" {
  description = "(Optional) The port on the instances to which traffic and healthchecks should be routed."
  type        = number
  default     = 80
}

variable "healthcheck_path" {
  description = "(Optional) The path of the healthcheck to determine whether instance is routable."
  type        = string
  default     = "/ping"
}

variable "target_group_arns" {
  description = "(Optional) A map of cluster names that should be routable for this service, and the ARN of their ingress target group."
  type        = map(string)
  default     = {}
}

variable "weights" {
  description = "(Optional) A map of cluster names if they should have special weighting applied.  Any clusters not included in this map will receive a weight of 1."
  type        = map(number)
  default     = {}
}

variable "restricted_cidrs" {
  description = "(Optional) If not empty, the ALB will set a source_ip condition to restrict access to only this list of CIDRs.  No source IP restrictions will be created if empty.  ALBs only allow a small handful of conditions, so this should only be used with 3-4 CIDRs; for any more create a new ALB and restrict access at the security group level."
  type        = list
  default     = []
}

variable "stickiness_enabled" {
  description = "(Optional) Whether target group stickiness is enabled."
  type        = bool
  default     = false
}

variable "stickiness_duration" {
  description = "(Optional) The time period, in seconds, during which requests from a client should be routed to the same target group. The range is 1-604800 seconds (7 days)."
  type        = number
  default     = 30
}

variable "shared_target_group" {
  description = "(Optional) Whether to enable the creation of a shared Target Group, and settings to assign it.  See locals.tf for options and defaults."
  default     = {}
}
