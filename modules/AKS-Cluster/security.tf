# Create Disk Encryption Set if CMK is requested
resource "azurerm_disk_encryption_set" "des" {
  for_each = { 
    for k, v in var.aks_clusters : k => v 
    if try(v.cmk_enabled, false) == true && v.cmk_key_vault_key_id != null
  }

  name                = "des-${each.key}"
  resource_group_name = each.value.node_resource_group
  location            = each.value.location
  key_vault_key_id    = each.value.cmk_key_vault_key_id

  # If des_identity_id is provided, use UserAssigned, else SystemAssigned
  identity {
    type         = each.value.des_identity_id != null ? "UserAssigned" : "SystemAssigned"
    identity_ids = each.value.des_identity_id != null ? [each.value.des_identity_id] : []
  }

  tags = var.common_tags
}

# Grant access for DES to the Key Vault (only if using SystemAssigned)
# If using UserAssigned, we assume user handled role assignment in root module
resource "azurerm_role_assignment" "des_access" {
  for_each = {
    for k, v in azurerm_disk_encryption_set.des : k => v
    if v.identity[0].type == "SystemAssigned"
  }

  scope                = join("/", slice(split("/", each.value.key_vault_key_id), 0, 9)) # Extracts KeyVault ID from Key ID
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = each.value.identity[0].principal_id
}