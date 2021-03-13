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

variable "target_group_arns" {
  description = "(Optional) A list of ARNs for target groups that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "target_group_names" {
  description = "(Optional) A list of names for target groups that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "cluster_name" {
  description = "(Required) A unique name or identifier for the cluster."
  type        = string
}

####################################################################################################
# Cluster Baseline Variables
####################################################################################################

variable "cluster_target_groups" {
  description = "(Optional) A map of target groups to create for this cluster, where a target group will be created for each key."
  default     = {}
}
