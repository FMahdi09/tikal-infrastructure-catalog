output "id" {
  description = "Id of the public ip"
  value       = azurerm_public_ip.ip.id
}

output "ip_address" {
  description = "The ip address that was allocated"
  value       = azurerm_public_ip.ip.ip_address
}