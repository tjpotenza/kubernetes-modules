variable "ha_enabled" {
  type    = bool
  default = false
}

variable "vpc_name" {
  type = string
}

variable "ingress_lb_name" {
  type = string
}

variable "ingress_lb_listener_port" {
  type    = string
  default = "443"
}

variable "dns_zone" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "security_group_names" {
  type    = list
  default = []
}

variable "security_group_ids" {
  type    = list
  default = []
}

variable "cluster_name" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "ami_regex" {
  type    = string
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

variable "public_ingress_hostnames" {
  description = "A list of additional host names for the ALB to allow public traffic into."
  type        = list
  default     = []
}

variable "private_ingress_hostnames" {
  description = "A list of additional host names for the ALB to allow private traffic into."
  type        = list
  default     = []
}

variable "shared_target_group_arns" {
  description = "A map of the arns of shared-across-clusters target groups with which this cluster should be associated."
  type        = map
  default     = {}
}

variable "private_cidrs" {
  description = "List of CIDRs that should be permitted to access 'private' hostnames and services on the cluster."
  type        = list
  default     = []
}

variable "alb_rule_priorities" {
  description = "Priority values to assign to the ASG Listener Rule for routing public and private traffic to the cluster.  Must be an array of two values, and each priority for Local Listener Rules must be lower than the priority assigned to the Global Listener Rules."
  type        = list
  default     = [null, null]
}

variable "public_services" {
  description = "List of service names that will be made publically accessible under hostnames of format [{service}--{cluster_name}.{dns_zone}]."
  type        = list
  default     = []
}
