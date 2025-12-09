resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                     = each.key
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  public_network_access_enabled     = each.value.public_network_access_enabled
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  tags                     = merge(each.value.tags, var.common_tags)

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.cmk_enabled && length(trim(each.value.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id          = each.value.cmk_key_vault_key_id
      user_assigned_identity_id = length(trim(each.value.cmk_user_assigned_identity_id)) > 0 ? each.value.cmk_user_assigned_identity_id : null
    }
  }
}

# Legacy single-storage support (backward compatibility)
resource "azurerm_storage_account" "storage" {
  count = (var.storage_account_name != "") ? 1 : 0

  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}