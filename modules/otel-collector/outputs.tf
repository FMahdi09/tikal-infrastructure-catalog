output "ip_address" {
  description = "The private ip address of the otel collector"
  value       = azurerm_container_app_environment.this.static_ip_address
}