resource "azurerm_container_registry" "acr" {
  name                         = var.acr_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  sku                          = var.sku
  admin_enabled                = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # Optional tags (fully dynamic)
  tags = var.tags

  # Optional customer-managed key (CMK)
  # This will be created only when `encryption_key_vault_key_id` is provided.
  dynamic "encryption" {
    for_each = var.encryption_key_vault_key_id != null ? [var.encryption_key_vault_key_id] : []
    content {
      key_vault_key_id = encryption.value
    }
  }

  # Optional user-assigned identity used to access the key vault for CMK
  dynamic "identity" {
    for_each = var.encryption_identity_id != null ? [var.encryption_identity_id] : []
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value]
    }
  }
}

// Diagnostic settings should be created centrally using the `Diagnostic-Settings` module
// Example usage from a root module:
//
// module "acr" {
//   source = "../modules/Azure-Container-Registries"
//   ...
// }
//
// module "acr_diags" {
//   source = "../modules/Diagnostic-Settings"
//   target_resource_id         = module.acr.acr_id
//   log_analytics_workspace_id = var.central_log_analytics_workspace_id
//   enabled_logs = ["ContainerRegistryRepositoryEvents", "ContainerRegistryLoginEvents"]
//   enabled_metrics = ["AllMetrics"]
// }