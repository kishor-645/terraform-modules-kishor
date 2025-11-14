output "postgresql_flexible_server_id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
}

output "postgresql_flexible_server_fqdn" {
  description = "The fully qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.postgresql_flexible_server.fqdn
}
