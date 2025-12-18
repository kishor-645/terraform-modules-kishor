output "id" {
  description = "PostgreSQL Server Resource ID"
  value       = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "Fully Qualified Domain Name"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "name" {
  value = azurerm_postgresql_flexible_server.this.name
}