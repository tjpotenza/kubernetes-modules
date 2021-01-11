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

variable "name" {
  description = "Name of the service for which this module routes."
  type        = string
}

variable "hostnames" {
  description = "A list of hostnames which should be matched for this service"
  type        = list
  default     = []
}

variable "port" {
  description = "Port on the instances to which traffic and healthchecks should be routed."
  type        = number
  default     = 80
}

variable "healthcheck_path" {
  description = "Path of the healthcheck to determine whether instance is routable."
  type        = string
  default     = "/ping"
}

variable "private" {
  description = "Whether or not this endpoint should be publically or privately accessible."
  type        = bool
  default     = true
}

variable "private_cidrs" {
  description = "List of CIDRs that should be permitted to access 'private' hostnames and services on the cluster."
  type        = list
  default     = []
}

variable "alb_rule_priority" {
  description = "Priority value to assign to the ASG Listener Rule for routing public and private traffic to the cluster."
  type        = number
  default     = null
}
