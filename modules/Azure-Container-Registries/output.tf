# ============================================================================
# MULTI-RESOURCE OUTPUTS (Recommended)
# ============================================================================
output "acr_ids" {
  description = "Map of ACR resource IDs indexed by registry name."
  value       = { for name, acr in azurerm_container_registry.this : name => acr.id }
}

output "acr_login_servers" {
  description = "Map of ACR login servers indexed by registry name."
  value       = { for name, acr in azurerm_container_registry.this : name => acr.login_server }
}

output "registries" {
  description = "All registry objects with full details."
  value       = azurerm_container_registry.this
  sensitive   = false
}

# ============================================================================
# LEGACY SINGLE-RESOURCE OUTPUTS (Backward Compatibility - Deprecated)
# ============================================================================
output "acr_id" {
  description = "(Deprecated) Use 'acr_ids' map instead."
  value       = try(azurerm_container_registry.acr[0].id, null)
}

output "acr_login_server" {
  description = "(Deprecated) Use 'acr_login_servers' map instead."
  value       = try(azurerm_container_registry.acr[0].login_server, null)
}