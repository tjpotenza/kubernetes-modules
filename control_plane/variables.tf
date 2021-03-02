variable "ha_enabled" {
  description = "Control Plane: Whether the control plane is using an HA-compatible data store.  Runs as a single node using internal storage if false."
  type        = bool
  default     = false
}

variable "vpc_name" {
  description = "Name for the VPC within which the cluster will be created, based on the VPC's 'Name' tag."
  type        = string
}

variable "instance_type" {
  description = "Instance type to use when creating nodes."
  type        = string
  default     = "t2.micro"
}

variable "instance_cpu_credits" {
  description = "The credit option for CPU usage. Can be 'standard' or 'unlimited'. T3 instances are launched as unlimited by default. T2 instances are launched as standard by default."
  type        = string
  default     = null
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

variable "cluster_name" {
  description = "A unique name or identifier for the cluster."
  type        = string
}

variable "key_name" {
  description = "Name for the SSH keypair to associate with each instance."
  type        = string
  default     = null
}

variable "ami_regex" {
  description = "The regular expression to use when looking up the AMI by name to use for each instance."
  type        = string
}

variable "k3s_channel" {
  description = "Channel of K3S to install.  See official K3S docs for full list of valid values."
  type        = string
  default     = "stable"
}

variable "k3s_version" {
  description = "Version of K3S to install.  If set, overrides the setting specified in var.k3s_channel."
  type        = string
  default     = ""
}

variable "instances" {
  description = "The number of instances for this role to create."
  type        = number
  default     = 1
}

variable "target_group_arns" {
  description = "A map of the arns of shared-across-clusters target groups with which this cluster should be associated."
  type        = map
  default     = {}
}

variable "external" {
  description = "Config for external access to the cluster."
  default     = {}
}

variable "internal" {
  description = "Config for internal access to the cluster."
  default     = {}
}

variable "root_block_device" {
  description = "Map of the values for configuring an instance's root block device.  Supported ptions are [ volume_type, volume_size, iops, delete_on_termination, encrypted ]."
  default     = {}
}
