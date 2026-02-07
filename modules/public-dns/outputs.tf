output "resource_group_name" {
  description = "The name of the resource group in which the public dns zone is deployed"
  value       = azurerm_resource_group.rg.name
}

output "dns_zone_name" {
  description = "The name of the created public dns zone"
  value       = azurerm_dns_zone.dns_public.name
}