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
# Control Plane & Node Group Variables
####################################################################################################

variable "instances" {
  description = "(Optional) The number of instances to be created in this group."
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "(Optional) The AWS instance type to use for new instances."
  type        = string
  default     = "t2.micro"
}

variable "instance_cpu_credits" {
  description = "(Optional) The credit option for CPU usage. Can be 'standard' or 'unlimited'. T3 instances are launched as unlimited by default. T2 instances are launched as standard by default."
  type        = string
  default     = null
}

variable "key_name" {
  description = "(Optional) Name for the SSH keypair to associate with each instance."
  type        = string
  default     = null
}

variable "ami_regex" {
  description = "(Required) A regular expression to use when looking up the AMI by name to use for each instance."
  type        = string
}

variable "root_block_device" {
  description = "(Optional) A map of the values for configuring an instance's root block device.  Supported options are [ volume_type, volume_size, iops, delete_on_termination, encrypted ]."
  default     = {}
}

variable "instance_profile_arn" {
  description = "(Required) The ARN for an IAM Instance Profile to associate with instances."
  type        = string
}

variable "k3s" {
  description = "(Optional) Options for configuring installation of k3s."
  default     = {}
}

####################################################################################################
# Control Plane Variables
####################################################################################################

variable "etcd" {
  description = "(Optional) Options for configuring the installation of etcd."
  default     = {}
}

variable "control_plane_sans" {
  description = "(Optional) Additional Subject Alternative Name records to include in the API Server certificate."
  type        = list
  default     = []
}
