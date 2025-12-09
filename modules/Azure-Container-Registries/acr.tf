# ============================================================================
# MULTI-RESOURCE REGISTRIES (Recommended)
# ============================================================================
resource "azurerm_container_registry" "this" {
  for_each = var.registries

  name                          = each.key
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  sku                           = each.value.sku
  admin_enabled                 = each.value.admin_enabled
  public_network_access_enabled = each.value.public_network_access_enabled

  # Merge common tags with registry-specific tags
  tags = merge(var.common_tags, each.value.tags)

  # Optional customer-managed key (CMK)
  # This will be created only when cmk_enabled is true and cmk_key_vault_key_id is provided
  dynamic "encryption" {
    for_each = each.value.cmk_enabled && length(trim(each.value.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id = each.value.cmk_key_vault_key_id
    }
  }

  # Optional user-assigned identity used to access the key vault for CMK
  dynamic "identity" {
    for_each = each.value.cmk_enabled && length(trim(each.value.cmk_identity_id)) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [each.value.cmk_identity_id]
    }
  }

  lifecycle {
    precondition {
      condition     = !each.value.cmk_enabled || (length(trim(each.value.cmk_key_vault_key_id)) > 0)
      error_message = "When CMK is enabled, cmk_key_vault_key_id must be provided."
    }
  }
}

# ============================================================================
# LEGACY SINGLE-RESOURCE ACR (Backward Compatibility - Deprecated)
# ============================================================================
resource "azurerm_container_registry" "acr" {
  count = (length(var.registries) == 0 && var.acr_name != "") ? 1 : 0

  name                         = var.acr_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  sku                          = var.sku
  admin_enabled                = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  dynamic "encryption" {
    for_each = var.encryption_key_vault_key_id != null ? [var.encryption_key_vault_key_id] : []
    content {
      key_vault_key_id = encryption.value
    }
  }

  dynamic "identity" {
    for_each = var.encryption_identity_id != null ? [var.encryption_identity_id] : []
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value]
    }
  }
}

// ============================================================================
// DIAGNOSTIC SETTINGS (Integrated Example)
// ============================================================================
// Diagnostic settings should be created centrally using the `Diagnostic-Settings` module
// Example usage from a root module:
//
// module "registries" {
//   source = "../modules/Azure-Container-Registries"
//   registries = {
//     "prod-acr" = { ... }
//   }
// }
//
// module "acr_diags" {
//   for_each               = module.registries.acr_ids
//   source                 = "../modules/Diagnostic-Settings"
//   target_resource_id     = each.value
//   log_analytics_workspace_id = var.central_log_analytics_workspace_id
//   enabled_logs           = ["ContainerRegistryRepositoryEvents", "ContainerRegistryLoginEvents"]
//   enabled_metrics        = ["AllMetrics"]
// }

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