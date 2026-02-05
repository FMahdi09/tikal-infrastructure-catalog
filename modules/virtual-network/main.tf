resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-networking-rg"
  location = var.region
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-${var.region}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  private_endpoint_network_policies = each.value.private_endpoint_network_policies != null ? each.value.private_endpoint_network_policies : "Disabled"

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
