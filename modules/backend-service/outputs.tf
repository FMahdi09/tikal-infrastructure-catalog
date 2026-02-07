output "hostname" {
  description = "The hostname of the service (can only be accessed via private network)"
  value       = azurerm_linux_web_app.service.default_hostname
}

output "webhook_url" {
  description = "The url which webhooks can use to notifiy the service to pull a new image"
  value       = "https://${azurerm_linux_web_app.service.site_credential.0.name}:${azurerm_linux_web_app.service.site_credential.0.password}@${azurerm_linux_web_app.service.name}.scm.azurewebsites.net/api/registry/webhook"
}