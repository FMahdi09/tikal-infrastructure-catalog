locals {
  certificate_name = "certificate"

  http_health_check_probe_name = "http-health-check-probe"

  backend_http_settings_name = "backend-http-settings"

  frontend_ip_configuration_name = "frontend-ip-configuration"
  frontend_port_name             = "frontend-port"
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault_certificate" "certificate" {
  name         = var.certificate_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-gateway-rg"
  location = var.region
}

resource "azurerm_user_assigned_identity" "gateway" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  name                = "gateway-identity"
}

resource "azurerm_key_vault_access_policy" "gateway" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.gateway.principal_id

  certificate_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_application_gateway" "gateway" {
  name                = "gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region

  zones = ["1"]

  sku {
    name     = "Basic"
    tier     = "Basic"
    capacity = 1
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gateway.id]
  }

  ssl_certificate {
    name                = local.certificate_name
    key_vault_secret_id = data.azurerm_key_vault_certificate.certificate.versionless_secret_id
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_id
  }

  probe {
    name                                      = local.http_health_check_probe_name
    protocol                                  = "Http"
    path                                      = "/healthcheck"
    interval                                  = 240
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      body        = "Healthy"
      status_code = [200]
    }
  }

  backend_http_settings {
    name                                = local.backend_http_settings_name
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    probe_name                          = local.http_health_check_probe_name
    pick_host_name_from_backend_address = true
  }

  dynamic "http_listener" {
    for_each = var.listeners
    content {
      name                           = "${http_listener.key}-listener"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      protocol                       = "Https"
      ssl_certificate_name           = local.certificate_name
      host_name                      = http_listener.value.hostname
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.listeners
    content {
      name                       = "${request_routing_rule.key}-rule"
      priority                   = request_routing_rule.value.priority
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.key}-listener"
      backend_address_pool_name  = "${request_routing_rule.key}-pool"
      backend_http_settings_name = local.backend_http_settings_name
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.listeners
    content {
      name  = "${backend_address_pool.key}-pool"
      fqdns = [backend_address_pool.value.fqdn]
    }
  }
}