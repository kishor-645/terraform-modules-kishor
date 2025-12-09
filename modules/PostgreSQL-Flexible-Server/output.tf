output "postgresql_servers" {
  description = "Map of all created PostgreSQL Flexible Servers with their ids and fqdns"
  value = {
    for k, v in azurerm_postgresql_flexible_server.this : k => {
      id   = v.id
      fqdn = v.fqdn
      name = v.name
    }
  }
}

# Legacy outputs (backward compatibility)
output "postgresql_flexible_server_id" {
  description = "(Deprecated) Use postgresql_servers output instead"
  value       = try(azurerm_postgresql_flexible_server.postgresql_flexible_server[0].id, "")
}

output "postgresql_flexible_server_fqdn" {
  description = "(Deprecated) Use postgresql_servers output instead"
  value       = try(azurerm_postgresql_flexible_server.postgresql_flexible_server[0].fqdn, "")
}
