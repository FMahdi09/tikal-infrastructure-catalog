output "name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.current.name
}

output "url" {
  description = "The url of the container registry"
  value       = azurerm_container_registry.current.login_server
}

output "resource_group_name" {
  description = "The name of the resource group where the container registry is deployed"
  value       = azurerm_resource_group.rg.name
}