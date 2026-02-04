resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-container-registry-rg"
  location = var.region
}

resource "azurerm_container_registry" "current" {
  name                = "ContainerRegistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.sku
  admin_enabled       = false
}
