output "hostname" {
  description = "The hostname of the service (can only be accessed via private network)"
  value       = azurerm_linux_web_app.service.default_hostname
}