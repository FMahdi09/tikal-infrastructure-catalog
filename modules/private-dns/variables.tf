variable "region" {
  description = "The region where the private dns zone will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the private dns zone will be deployed"
  type        = string
}

variable "virtual_network_id" {
  description = "The id of the virtual network in which the private dns zone will be deployed"
  type        = string
}