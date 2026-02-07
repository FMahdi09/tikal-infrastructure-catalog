resource "azurerm_container_registry_webhook" "frontend" {
  for_each = var.acr_webhook_config

  name                = "${each.key}Webhook"
  resource_group_name = var.resource_group_name
  registry_name       = var.container_registry_name
  location            = var.region

  service_uri = each.value.service_url
  status      = "enabled"
  scope       = each.value.image_name
  actions     = ["push"]
}