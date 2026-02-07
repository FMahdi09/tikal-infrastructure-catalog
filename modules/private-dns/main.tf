resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-private-dns-rg"
  location = var.region
}

resource "azurerm_private_dns_zone" "dns_private" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.current.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_private" {
  name                  = "${var.environment}-${var.region}-private-dnszonelink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_private.name
  virtual_network_id    = var.virtual_network_id
}