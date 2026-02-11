resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-public-dns-rg"
  location = var.region
}

resource "azurerm_dns_zone" "dns_public" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "dns_a_records" {
  for_each            = var.dns_a_records
  name                = each.key
  zone_name           = azurerm_dns_zone.dns_public.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [each.value.ip_address]
}