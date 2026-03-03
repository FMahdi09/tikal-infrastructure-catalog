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
  name                               = "${var.environment}-${var.region}-otel-container-env"
  location                           = azurerm_resource_group.rg.location
  resource_group_name                = azurerm_resource_group.rg.name
  infrastructure_subnet_id           = var.subnet_id
  infrastructure_resource_group_name = "${var.environment}-${var.region}-otel-container-env-infra"
  internal_load_balancer_enabled     = true

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 0
  }
}

resource "azurerm_private_dns_zone" "dns_private" {
  name                = azurerm_container_app_environment.this.default_domain
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_private" {
  name                  = "${var.environment}-${var.region}-otel-private-dnszonelink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_private.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_dns_a_record" "dns_a_records" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.dns_private.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.this.static_ip_address]
}

resource "azurerm_container_app_environment_storage" "config" {
  name                         = "otel-config-storage"
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.this.name
  share_name                   = azurerm_storage_share.this.name
  access_key                   = azurerm_storage_account.this.primary_access_key
  access_mode                  = "ReadOnly"
}

resource "azurerm_container_app" "this" {
  name                         = "otel-container"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "otel-collector"
      image  = "otel/opentelemetry-collector-contrib:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      volume_mounts {
        name = "config"
        path = "/etc/otelcol-contrib"
      }

      env {
        name  = "GRAFANA_CLOUD_INSTANCE_ID"
        value = var.grafana_cloud_instance_id
      }

      env {
        name  = "GRAFANA_CLOUD_API_KEY"
        value = var.grafana_cloud_api_key
      }

      env {
        name  = "GRAFANA_CLOUD_OTLP_ENDPOINT"
        value = var.grafana_cloud_otlp_endpoint
      }
    }

    volume {
      name         = "config"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.config.name
    }
  }

  ingress {
    external_enabled = true
    target_port      = 4318
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}