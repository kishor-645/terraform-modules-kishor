resource "azurerm_disk_encryption_set" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_key_id    = var.key_vault_key_id

  # Toggle between SystemAssigned or UserAssigned based on input
  identity {
    type         = var.identity_id != null ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_id != null ? [var.identity_id] : []
  }

  tags = var.tags
}