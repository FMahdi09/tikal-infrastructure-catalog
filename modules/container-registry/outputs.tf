output "name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.current.name
}

output "url" {
  description = "The url of the container registry"
  value       = azurerm_container_registry.current.login_server
}