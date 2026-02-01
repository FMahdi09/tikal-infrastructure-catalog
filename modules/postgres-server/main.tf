resource "azurerm_resource_group" "postgres" {
  name     = "${var.environment}-${var.region}-postgres-rg"
  location = var.region
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.postgres.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.environment}-${var.region}-postgres-dnszonelink"
  resource_group_name   = azurerm_resource_group.postgres.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = "${var.environment}-${var.region}-postgres-server"
  resource_group_name           = azurerm_resource_group.postgres.name
  location                      = var.region
  version                       = "16"
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  administrator_login           = "postgres"
  administrator_password        = random_password.db_admin_password.result
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  backup_retention_days         = 7
  public_network_access_enabled = false
  zone                          = "2"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "random_password" "db_admin_password" {
  length           = 20
  special          = true
  lower            = true
  upper            = true
  override_special = "!#"
}
