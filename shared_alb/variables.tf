variable "name" {
    description = "Name for the ALB to be created."
    type        = string
}

variable "internal" {
    description = "Whether the ALB is internal or external."
    type        = bool
    default     = false
}

variable "security_group_names" {
    description = "List of additional security groups by name which should be associated with the ALB."
    type        = list
    default     = []
}

variable "security_group_ids" {
    description = "List of additional security groups by id which should be associated with the ALB."
    type        = list
    default     = []
}

variable "vpc_id" {
  description = "ID for the VPC within which resources will be created."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnets within which resources will be created."
  type        = list
  default     = null
}

variable "vpc_tags" {
  description = "Tags to target when looking up the VPC within which resources will be created.  Not used if vpc_id is set."
  type        = map
  default     = null
}

variable "subnet_filters" {
  description = "Map of filters to be use when looking up subnets.  Not used if subnet_ids is set."
  type        = map
  default     = {}
}

variable "certificate_arn" {
    description = "ARN of an existing ACM Certificate for use with TLS traffic."
    type        = string
    default     = null
}

variable "ingress_cidr_blocks" {
    description = "List of CIDRs to allow ingress from which traffic should be allowed into the load balancer."
    type        = list
    default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
    description = "List of CIDRs to allow egress from which traffic should be allowed from the load balancer."
    type        = list
    default     = ["0.0.0.0/0"]
}
