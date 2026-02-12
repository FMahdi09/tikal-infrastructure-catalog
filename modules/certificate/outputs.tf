output "key_vault_id" {
  description = "The id of the key vault where the certificates are stored"
  value       = azurerm_key_vault.current.id
}

output "key_vault_secret_ids" {
  description = "The ids of the certificates inside the key vault"
  value = {
    for k, v in data.azurerm_key_vault_certificate.certificates : k => {
      secret_id = v.versionless_secret_id
    }
  }
}