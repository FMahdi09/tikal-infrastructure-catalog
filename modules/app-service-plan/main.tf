resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-service-plan-rg"
  location = var.region
}

resource "azurerm_service_plan" "current" {
  name                = "${var.environment}-${var.region}-app-service-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = var.os_type
  sku_name            = var.sku
}