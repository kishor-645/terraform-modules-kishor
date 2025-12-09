output "key_vaults" {
  description = "Map of all created key vaults with their ids and names"
  value = {
    for k, v in azurerm_key_vault.this : k => {
      id    = v.id
      name  = v.name
      vault_uri = v.vault_uri
      resource_group = v.resource_group_name
      location       = v.location
    }
  }
}

# Correct tenant output name (keep backward-compat alias)
output "kv_tenant_id" {
  description = "Azure tenant id for the running subscription"
  value       = data.azurerm_client_config.current.tenant_id
}

output "kv_tenanet_id" {
  description = "(Deprecated alias) Misspelled tenant id kept for backward compatibility. Use kv_tenant_id instead."
  value       = data.azurerm_client_config.current.tenant_id
}

/* legacy single-vault outputs removed. Use `key_vaults` output map instead. */