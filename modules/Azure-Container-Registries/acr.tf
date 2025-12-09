resource "azurerm_container_registry" "this" {
  for_each = var.registries

  name                          = each.key
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  sku                           = each.value.sku
  admin_enabled                 = try(each.value.admin_enabled, false)
  public_network_access_enabled = try(each.value.public_network_access_enabled, true)

  # Merge tags
  tags = merge(var.common_tags, try(each.value.tags, {}))

  # --------------------------------------------------------------------------
  # 1. Identity Block: Needed so ACR can verify permissions on the KeyVault
  # --------------------------------------------------------------------------
  dynamic "identity" {
    # If cmk_enabled is true, force creation of this block without checking string length
    for_each = try(each.value.cmk_enabled, false) == true ? [1] : []
    
    content {
      type         = "UserAssigned"
      identity_ids = [each.value.cmk_identity_id]
    }
  }

dynamic "encryption" {
    # Check if CMK enabled AND key ID is present
    for_each = try(each.value.cmk_enabled, false) == true && try(each.value.cmk_key_vault_key_id, null) != null ? [1] : []
    
    content {
      # only add this when ACR fail to attach with CMK (in V.3 ) -> enabled = true
      key_vault_key_id   = each.value.cmk_key_vault_key_id
      identity_client_id = each.value.cmk_identity_client_id
    }
  }
  }