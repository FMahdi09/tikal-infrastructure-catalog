variable "subnets" {
  description = "Map of subnets to create inside the virual network"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
  }))
}

variable "address_space" {
  description = "The address space of the virtual network"
  type        = string
}

variable "region" {
  description = "The region where the virtual network will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the virtual network will be deployed"
  type        = string
}
