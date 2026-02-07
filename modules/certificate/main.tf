locals {
  script_path = "${path.module}/Scripts"

  pending_csr = { for k, v in data.external.get_csr : k => v.result.csr }
  stored_csr  = { for k, v in azurerm_key_vault_secret.csr_storage : k => v.value }
  csr_lookup  = merge(local.stored_csr, local.pending_csr)
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.region}-certificate-rg"
  location = var.region
}

resource "time_rotating" "cert_rotation" {
  rotation_days = 30
}

resource "null_resource" "rotate_certificates_trigger" {
  triggers = {
    value = time_rotating.cert_rotation.id
  }
}

resource "azurerm_key_vault" "current" {
  name                        = "tikal-gateway-keyvault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azuread_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
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

data "external" "get_csr" {
  for_each   = { for key, value in var.certificates : key => value }
  program    = ["bash", "${local.script_path}/certmgmt.sh", "output", each.key, azurerm_key_vault.current.name]
  depends_on = [azurerm_key_vault_certificate.certificates]
}

resource "azurerm_key_vault_secret" "csr_storage" {
  for_each        = { for k, v in data.external.get_csr : k => v }
  key_vault_id    = azurerm_key_vault.current.id
  name            = "${each.key}-csr"
  content_type    = "text/plain"
  expiration_date = timeadd(timestamp(), "1128h") # 47 days
  value           = each.value.result.csr

  lifecycle {
    ignore_changes = [
      value,
      expiration_date
    ]
    # Forces replacement when the key vault is updated
    replace_triggered_by = [azurerm_key_vault_certificate.certificates[each.key]]
  }
}

resource "acme_registration" "current" {
  email_address = "fabian@mahdi.at"
}

resource "azuread_application_registration" "acme" {
  display_name = "${var.environment}-${var.region}-application-registration-acme"
}

resource "azuread_service_principal" "acme" {
  client_id                    = azuread_application_registration.acme.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "dns_zone" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.acme.object_id
}

resource "azuread_application_password" "acme" {
  application_id = azuread_application_registration.acme.id
}

resource "azurerm_key_vault_certificate" "certificates" {
  for_each     = var.certificates
  name         = each.key
  key_vault_id = azurerm_key_vault.current.id

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "EmailContacts"
      }

      trigger {
        days_before_expiry = 10
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = each.value["alternative_dns_names"]
      }

      subject            = each.value["subject"]
      validity_in_months = 2
    }
  }

  lifecycle {
    replace_triggered_by = [null_resource.rotate_certificates_trigger]
  }

  depends_on = [azurerm_key_vault_access_policy.client-config]
}

resource "acme_certificate" "certificates" {
  for_each                      = var.certificates
  account_key_pem               = acme_registration.current.account_key_pem
  revoke_certificate_on_destroy = true
  certificate_request_pem       = <<EOT
-----BEGIN CERTIFICATE REQUEST-----
${local.csr_lookup[each.key]}
-----END CERTIFICATE REQUEST-----
EOT
  min_days_remaining            = 33

  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_PRIVATE_ZONE        = false
      AZURE_RESOURCE_GROUP      = var.dns_resource_group_name
      AZURE_ZONE_NAME           = var.dns_zone_name
      AZURE_AUTH_METHOD         = "env"
      AZURE_ENVIRONMENT         = "public"
      AZURE_TENANT_ID           = data.azurerm_client_config.current.tenant_id
      AZURE_CLIENT_ID           = azuread_application_registration.acme.client_id
      AZURE_CLIENT_SECRET       = azuread_application_password.acme.value
      AZURE_SUBSCRIPTION_ID     = var.subscription_id
      AZURE_POLLING_INTERVAL    = "10"
      AZURE_PROPAGATION_TIMEOUT = "600"
    }
  }

  depends_on = [
    data.external.get_csr
  ]

  lifecycle {
    ignore_changes = [
      certificate_request_pem
    ]
    replace_triggered_by = [null_resource.rotate_certificates_trigger]
  }
}

resource "null_resource" "merge_pending_certificates" {
  for_each = { for k, v in acme_certificate.certificates : k => v }
  # Trigger if any certificate value changes
  triggers = {
    certificate_pem = each.value.certificate_pem
    issuer_pem      = each.value.issuer_pem
  }
  provisioner "local-exec" {
    command     = <<EOT
SIGNED_CERTIFICATE="CERTIFICATE
${each.value.certificate_pem}
${each.value.issuer_pem}
CERTIFICATE" ${local.script_path}/certmgmt.sh "merge" "${each.key}" "${azurerm_key_vault.current.name}"
EOT
    interpreter = ["bash", "-c"]
  }
  depends_on = [
    azurerm_key_vault_certificate.certificates,
    acme_certificate.certificates
  ]
}