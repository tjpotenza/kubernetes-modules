####################################################################################################
# Common Variables
####################################################################################################

variable "vpc_id" {
  description = "(Optional) The ID for the VPC within which resources will be created."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "(Optional) A list of subnets within which resources will be created."
  type        = list
  default     = null
}

variable "vpc_tags" {
  description = "(Optional) A map of tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set."
  type        = map
  default     = null
}

variable "subnet_filters" {
  description = "(Optional) A map of AWS filters to be use when looking up subnets.  Not used if subnet_ids is set."
  type        = map
  default     = {}
}

variable "security_group_names" {
  description = "(Optional) A list of additional security groups by name which should be associated with each instance."
  type        = list
  default     = []
}

variable "security_group_ids" {
  description = "(Optional) A list of additional security groups by id which should be associated with each instance."
  type        = list
  default     = []
}

####################################################################################################
# Shared ALB Variables
####################################################################################################

variable "name" {
  description = "(Required) A name for the ALB to be created."
  type        = string
}

variable "internal" {
  description = "(Optional) Whether the ALB is internal or external."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "(Required) The ARN of an existing ACM Certificate for use with TLS traffic."
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "(Optional) A list of ingress CIDRs from which traffic should be allowed into the load balancer."
  type        = list
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  description = "(Optional) A list of egress CIDRs from which traffic should be allowed out of the load balancer."
  type        = list
  default     = ["0.0.0.0/0"]
}
