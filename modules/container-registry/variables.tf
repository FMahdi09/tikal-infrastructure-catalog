variable "region" {
  description = "The region where the container registry will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the container registry will be deployed"
  type        = string
}

variable "sku" {
  description = "The sku of the container registry"
  type        = string
}