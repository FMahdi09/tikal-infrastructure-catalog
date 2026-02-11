resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-public-ip-rg"
  location = var.region
}

resource "azurerm_public_ip" "ip" {
  name                = "public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  zones = ["1"]
}