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
  source            = ".${path.module}/config.yaml"
}

resource "azurerm_container_group" "otel-containergroup" {
  name                = "${var.environment}-${var.region}-otel-container-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"

  container {
    name  = "otel-collector"
    image = "otel/opentelemetry-collector-contrib"

    cpu    = "0.2"
    memory = "0.5"

    ports {
      port     = 4317
      protocol = "TCP"
    }
    ports {
      port     = 4318
      protocol = "TCP"
    }
    ports {
      port     = 13133
      protocol = "TCP"
    }

    environment_variables = {
      "GRAFANA_CLOUD_INSTANCE_ID"   = var.grafana_cloud_instance_id,
      "GRAFANA_CLOUD_API_KEY"       = var.grafana_cloud_api_key,
      "GRAFANA_CLOUD_OTLP_ENDPOINT" = var.grafana_cloud_otlp_endpoint,
    }

    volume {
      name                 = "config"
      mount_path           = "/etc/otelcol-contrib"
      storage_account_name = azurerm_storage_account.this.name
      storage_account_key  = azurerm_storage_account.this.primary_access_key
      share_name           = azurerm_storage_share.this.name
    }
  }

  subnet_ids = [var.subnet_id]
}