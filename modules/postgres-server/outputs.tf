output "credentials" {
  description = "Admin credentials of the postgres servier"
  value = {
    user     = "postgres"
    password = random_password.db_admin_password.result
  }
  sensitive = true
}

output "name" {
  description = "Name of the database server"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "resource_group_name" {
  description = "Name of the resource group of the database server"
  value       = azurerm_resource_group.postgres.name
}