# Output for the ID (Returns a Map: ACR Name => ID)
output "acr_ids" {
  description = "Map of IDs for the created Container Registries"
  value       = { for k, v in azurerm_container_registry.this : k => v.id }
}

# Output for the Login Server (Returns a Map: ACR Name => Login Server)
output "acr_login_servers" {
  description = "Map of Login Servers for the created Container Registries"
  value       = { for k, v in azurerm_container_registry.this : k => v.login_server }
}

# Optional: Admin Credentials (only populated if admin_enabled is true)
output "acr_admin_credentials" {
  description = "Map of Admin credentials (sensitive)"
  sensitive   = true
  value = {
    for k, v in azurerm_container_registry.this : k => {
      username = v.admin_username
      password = v.admin_password
    }
  }
}