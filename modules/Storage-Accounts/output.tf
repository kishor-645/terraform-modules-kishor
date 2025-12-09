output "storage_accounts" {
  description = "Map of all created storage accounts with their ids and endpoints"
  value = {
    for k, v in azurerm_storage_account.this : k => {
      id                    = v.id
      name                  = v.name
      primary_blob_endpoint = v.primary_blob_endpoint
    }
  }
}

# Legacy output (backward compatibility)
output "storage_account_id" {
  description = "(Deprecated) Use storage_accounts output instead"
  value       = try(azurerm_storage_account.storage[0].id, "")
}