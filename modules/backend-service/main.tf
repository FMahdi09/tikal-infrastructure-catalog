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
  virtual_network_subnet_id = var.virtual_network_id

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
  subnet_id           = var.subnet_id

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

resource "azurerm_container_registry_webhook" "frontend" {
  name                = "${var.name}Webhook"
  resource_group_name = azurerm_resource_group.rg.name
  registry_name       = var.container_registry_name
  location            = var.region

  service_uri = "https://${azurerm_linux_web_app.service.site_credential.0.name}:${azurerm_linux_web_app.service.site_credential.0.password}@${azurerm_linux_web_app.service.name}.scm.azurewebsites.net/api/registry/webhook"
  status      = "enabled"
  scope       = var.image_name
  actions     = ["push"]
}