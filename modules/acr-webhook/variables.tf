variable "acr_webhook_config" {
  description = "The configuration for the webhooks which should be created"
  type = map(object({
    name        = string
    image_name  = string
    service_url = string
  }))
}

variable "region" {
  description = "The region where all webhooks will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where all webhooks will be deployed"
  type        = string
}

variable "container_registry_name" {
  description = "The name of the container registry where all webhooks will use"
  type        = string
}