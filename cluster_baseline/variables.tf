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

variable "security_group_names" {
  description = "List of additional security groups by name which should be associated with each instance."
  type        = list
  default     = []
}

variable "security_group_ids" {
  description = "List of additional security groups by id which should be associated with each instance."
  type        = list
  default     = []
}

variable "target_group_arns" {
  description = "A list of target groups by arn that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "target_group_names" {
  description = "A list of target groups by name that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "cluster_name" {
  description = "A unique name or identifier for the cluster."
  type        = string
}

variable "ingress" {
  description = "Map of load balancer associations."
  default     = {}
}
