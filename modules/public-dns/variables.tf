variable "region" {
  description = "The region where the public dns zone will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the public dns zone will be deployed"
  type        = string
}

variable "domain_name" {
  description = "The name of the domain for this public dns zone"
  type        = string
}

variable "dns_a_records" {
  description = "Map of dns a records to create with their assigned ip address"
  type = map(object({
    ip_address = list(string)
  }))
}