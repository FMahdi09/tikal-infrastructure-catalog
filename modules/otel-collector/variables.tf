variable "region" {
  description = "The region where the otel collector will be deployed"
  type        = string
}

variable "environment" {
  description = "The environment where the otel collector will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet in which the otel collector will be deployed"
  type        = string
}

variable "grafana_cloud_instance_id" {
  type        = string
  description = "The instance id for the grafana cloud account used to ingest exported otel"
}

variable "grafana_cloud_api_key" {
  type        = string
  description = "The api key for the grafana cloud account used to ingest exported otel"
}

variable "grafana_cloud_otlp_endpoint" {
  type        = string
  description = "The endpoint to which otel should be exported"
}