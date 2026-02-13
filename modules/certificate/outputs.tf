output "key_vault_id" {
  description = "The id of the key vault where the certificates are stored"
  value       = azurerm_key_vault.current.id
}