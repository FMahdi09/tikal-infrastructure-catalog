variable "region" {
  description = "The region where the gateway will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the gateway will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet used by the gateway"
  type        = string
}

variable "public_ip_id" {
  description = "The id of the public ip used by the gateway"
  type        = string
}

variable "key_vault_id" {
  description = "The id of the keyvault which contains the needed certificates"
  type        = string
}

variable "certificate_name" {
  description = "The name of the certificate which should be used"
  type        = string
}

variable "listeners" {
  description = "Map of listeners of the gateway"
  type = map(object({
    hostname = string
    fqdn     = string
    priority = number
  }))
}