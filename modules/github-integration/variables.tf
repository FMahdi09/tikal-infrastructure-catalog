variable "region" {
  description = "The region where the github network integration will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the github network integration will be deployed"
  type        = string
}

variable "github_database_id" {
  description = "The database id of the github organization"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet in which the github network integration will be deployed"
  type        = string
}