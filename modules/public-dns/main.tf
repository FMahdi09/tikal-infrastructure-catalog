resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-public-dns-rg"
  location = var.region
}

resource "azurerm_dns_zone" "dns_public" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.rg.name
}