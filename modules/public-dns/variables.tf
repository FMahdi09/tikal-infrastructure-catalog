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