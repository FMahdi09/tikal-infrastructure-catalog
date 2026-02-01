variable "region" {
  description = "The region where the postgres server will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the postgres server will be deployed"
  type        = string
}

variable "virtual_network_id" {
  description = "The id of the virtual network in which the postgres server will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet in which the postgres server will be deployed"
  type        = string
}
