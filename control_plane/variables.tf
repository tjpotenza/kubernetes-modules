variable "ha_enabled" {
  type    = bool
  default = false
}

variable "vpc_name" {
  type = string
}

variable "internal_dns_zone" {
  description = "Zone name for internal DNS records.  Internal records will not be created if no value is provided."
  type        = string
  default     = ""
}

variable "external_dns_zone" {
  description = "Zone name for external DNS records.  External records will not be created if no value is provided."
  type        = string
  default     = ""
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_cpu_credits" {
  type    = string
  default = null
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
