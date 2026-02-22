resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-github-rg"
  location = var.region
}

resource "azapi_resource" "github_network_settings" {
  type                      = "GitHub.Network/networkSettings@2024-04-02"
  name                      = "github-network-settings"
  location                  = azurerm_resource_group.rg.location
  parent_id                 = azurerm_resource_group.rg.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      businessId = var.github_database_id
      subnetId   = var.subnet_id
    }
  })
  response_export_values = ["tags.GitHubId"]

  lifecycle {
    ignore_changes = [tags]
  }
}