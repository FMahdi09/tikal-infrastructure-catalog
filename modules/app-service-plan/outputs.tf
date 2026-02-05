output "id" {
  description = "The id of the app service plan"
  value       = azurerm_service_plan.current.id
}