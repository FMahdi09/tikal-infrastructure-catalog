output "fqdn" {
  description = "The fqdn of the otel collector"
  value       = azurerm_container_app.this.ingress[0].fqdn
}