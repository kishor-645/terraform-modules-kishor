resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  public_network_access_enabled = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  blob_properties {
    delete_retention_policy {
      days = 7  # Set the number of days you want to retain the soft deleted blobs
    }
  }
#   tags = var.tags
}