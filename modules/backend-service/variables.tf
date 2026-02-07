variable "name" {
  description = "The name of the backend service"
  type        = string
}

variable "subscription_id" {
  description = "The id of the active azure subscription"
  type        = string
}

variable "region" {
  description = "The region where the backend service will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the backend service will be deployed"
  type        = string
}

variable "virtual_network_id" {
  description = "The id of the virtual network in which the service will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet in which the private endpoint used to access the service will be deployed"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The id of the private dns zone used by the private endpoint"
  type        = string
}

variable "image_name" {
  description = "The name of the docker image which will automatically be pulled from the provided container registry"
  type        = string
}

variable "container_registry_name" {
  description = "The name of the container registry which the service will query for the given image"
  type        = string
}

variable "container_registry_url" {
  description = "The url of the container registry which the service will query for the given image"
  type        = string
}

variable "service_plan_id" {
  description = "The id of the service plan used to provision resources for this service"
  type        = string
}