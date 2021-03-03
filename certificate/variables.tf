variable "name" {
    description = "A name to associate with the certificate."
    type        = string
    default     = ""
}

variable "domain_name" {
    description = "Primary domain name to associate with the certificate."
    type        = string
}

variable "subject_alternative_names" {
    description = "Additional Subject Alternative Names to associate with the certificate."
    type        = list
    default     = []
}

variable "validation_zone_id" {
    description = "ID of the Route53 zone in which the records should be created for DNS-based certificate validation."
    type        = string
}

variable "validation_zone_id_overrides" {
    description = "(Optional) A map where each key is one of the subject alternative names and each value is the Route53 Zone ID to use for DNS-based ACM validation.  Only needed for SANs that require a different Route53 zone than the one in validation_zone_id."
    default     = {}
}
