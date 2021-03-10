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
  description = "A list of ARNs for target groups that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "target_group_names" {
  description = "A list of names for target groups that should be associated with cluster instances."
  type        = list
  default     = []
}

variable "cluster_name" {
  description = "A unique name or identifier for the cluster."
  type        = string
}

variable "group_name" {
  description = "A unique name or identifier for this particular group of control plane instances or nodes."
  type        = string
  default     = null
}

variable "instances" {
  description = "The number of instances for this role to create."
  type        = number
  default     = 1
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

variable "key_name" {
  description = "Name for the SSH keypair to associate with each instance."
  type        = string
  default     = null
}

variable "ami_regex" {
  description = "The regular expression to use when looking up the AMI by name to use for each instance."
  type        = string
}

variable "k3s" {
  description = "Options for configuring installation of k3s itself."
  default     = {}
}

variable "etcd" {
  description = "Options for configuring the installation of etcd itself."
  default     = {}
}

variable "root_block_device" {
  description = "Map of the values for configuring an instance's root block device.  Supported ptions are [ volume_type, volume_size, iops, delete_on_termination, encrypted ]."
  default     = {}
}

variable "instance_profile_arn" {
  description = "ARN for an IAM Instance Profile to associate with instances."
  type        = string
  default     = null
}

variable "control_plane_sans" {
  description = "Control-Plane: Additional Subject Alternative Name records to include in the API Server certificate."
  type        = list
  default     = []
}
