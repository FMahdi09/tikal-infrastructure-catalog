variable "region" {
  description = "The region where the app service plan will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the app service plan will be deployed"
  type        = string
}

variable "sku" {
  description = "The sku of the app service plan"
  type        = string
}

variable "os_type" {
  description = "The os type of the app service plan"
  type        = string
}