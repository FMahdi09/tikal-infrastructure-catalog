resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-otel-rg"
  location = var.region
}

resource "azurerm_storage_account" "this" {
  name                     = "tikalotelcollector"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_share" "this" {
  name               = "${var.environment}-${var.region}-otel-storage-share"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 1
  enabled_protocol   = "SMB"
}

resource "azurerm_storage_share_file" "otel_config_file" {
  name              = "config.yaml"
  storage_share_url = azurerm_storage_share.this.url
  source            = "${path.module}/config.yaml"
}

resource "azurerm_container_app_environment" "this" {
  name                           = "${var.environment}-${var.region}-otel-container-env"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = true
}