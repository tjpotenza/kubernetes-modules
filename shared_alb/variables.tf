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
    description = "Name for the VPC within which the ALB will be created."
    type        = string
}

variable "subnets" {
    description = "List of Subnets to pass into the ALB."
    type        = list
    default     = []
}

variable "certificate_arn" {
    description = "ARN of an ACM Certificate for use with TLS traffic."
    type        = string
}
