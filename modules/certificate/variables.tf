variable "region" {
  description = "The region where the gateway will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the gateway will be deployed"
  type        = string
}

variable "subscription_id" {
  description = "The id of the active azure subscription"
  type        = string
}

variable "dns_resource_group_name" {
  description = "The name of the resource group where the dns zone is deployed (needed for dns challenge)"
  type        = string
}

variable "dns_zone_name" {
  description = "The name of the dns zone used in the dns challenge"
  type        = string
}

variable "certificate" {
  description = "The subject and dns names of the used certificate of the gateway"
  type = object({
    subject               = string
    alternative_dns_names = list(string)
  })
}