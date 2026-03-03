output "ip_address" {
  description = "The private ip address of the otel collector"
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "fqdn" {
  description = "The fqdn of the otel collector"
  value       = azurerm_container_app.this.ingress[0].fqdn
}