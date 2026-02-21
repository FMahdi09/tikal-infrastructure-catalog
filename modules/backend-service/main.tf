resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-${var.name}-rg"
  location = var.region
}

resource "azurerm_user_assigned_identity" "identity" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${var.name}-identity"
}

resource "azurerm_role_assignment" "arc-pull" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_linux_web_app" "service" {
  name                      = var.name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.region
  service_plan_id           = var.service_plan_id
  virtual_network_subnet_id = var.service_subnet_id

  site_config {
    ip_restriction_default_action = "Deny"

    ip_restriction {
      action = "Allow"

      service_tag = "AzureContainerRegistry"
    }

    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.identity.client_id

    application_stack {
      docker_image_name   = var.image_name
      docker_registry_url = "https://${var.container_registry_url}"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  app_settings = {
    DOCKER_ENABLE_CI = "true"
    AZURE_CLIENT_ID  = azurerm_user_assigned_identity.identity.client_id
  }
}

resource "azurerm_private_endpoint" "identity-api" {
  name                = "${var.environment}-${var.region}-${var.name}-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = var.endpoint_subnet_id

  private_dns_zone_group {
    name                 = "${var.name}-private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  private_service_connection {
    name                           = "${var.name}-private-endpoint-connection"
    private_connection_resource_id = azurerm_linux_web_app.service.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

data "azurerm_postgresql_flexible_server" "postgres" {
  name                = var.database_server_name
  resource_group_name = var.database_resource_group_name
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = "${var.name}-db"
  server_id = data.azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "UTF8"

  lifecycle {
    prevent_destroy = false
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "current" {
  name                        = "tikal-${var.name}-keyvault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "identity" {
  key_vault_id = azurerm_key_vault.current.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.identity.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_secret" "db_password" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "Database--Password"
  value        = var.database_credentials.password

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "azurerm_key_vault_secret" "db_username" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "Database--Username"
  value        = var.database_credentials.user

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "azurerm_key_vault_secret" "db_port" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "Database--Port"
  value        = 5432

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "azurerm_key_vault_secret" "db_host" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "Database--Host"
  value        = data.azurerm_postgresql_flexible_server.postgres.fqdn

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "azurerm_key_vault_secret" "identity_db_name" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "Database--DatabaseName"
  value        = "${var.name}-db"

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "azurerm_key_vault_access_policy" "client-config" {
  key_vault_id = azurerm_key_vault.current.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]

  storage_permissions = [
    "Backup",
    "Delete",
    "DeleteSAS",
    "Get",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update"
  ]
}