output "private_dns_zone_id" {
  description = "Id of the private dns zone"
  value       = azurerm_private_dns_zone.dns_private.id
}