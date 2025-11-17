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

# Diagnostic settings: optional, created only when a Log Analytics workspace id is provided
resource "azurerm_monitor_diagnostic_setting" "acr" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.acr_name}"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}