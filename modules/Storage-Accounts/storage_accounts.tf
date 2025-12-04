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
  dynamic "customer_managed_key" {
    for_each = var.cmk_enabled && length(trim(var.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id = var.cmk_key_vault_key_id
      user_assigned_identity_id = length(trim(var.cmk_user_assigned_identity_id)) > 0 ? var.cmk_user_assigned_identity_id : null
    }
  }
#   tags = var.tags
}