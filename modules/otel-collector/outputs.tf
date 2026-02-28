output "ip_address" {
  description = "The private ip address of the otel collector"
  value       = azurerm_container_group.otel-containergroup.ip_address
}