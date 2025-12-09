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