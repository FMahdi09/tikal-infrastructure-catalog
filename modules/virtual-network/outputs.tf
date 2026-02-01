output "subnets" {
  description = "Map of subnet information"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "virtual_network_id" {
  description = "Id of the virtual network"
  value       = azurerm_virtual_network.main.id
}
