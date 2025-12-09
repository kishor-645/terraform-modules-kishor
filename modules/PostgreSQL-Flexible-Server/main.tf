# Create multiple PostgreSQL Flexible Servers
resource "azurerm_postgresql_flexible_server" "this" {
  for_each = var.postgresql_servers

  name                          = each.key
  resource_group_name           = var.resource_group_name
  location                      = var.location
  administrator_login           = each.value.admin_username
  administrator_password        = each.value.admin_password
  public_network_access_enabled = each.value.public_network_access_enabled
  zone                          = each.value.zone
  sku_name                      = each.value.sku_name
  storage_mb                    = each.value.storage_mb
  storage_tier                  = each.value.storage_tier
  version                       = each.value.postgresql_version
  auto_grow_enabled             = each.value.auto_grow_enabled
  geo_redundant_backup_enabled  = each.value.geo_redundant_backup_enabled
  tags                          = merge(each.value.tags, var.common_tags)

  authentication {
    active_directory_auth_enabled = each.value.active_directory_auth_enabled
    password_auth_enabled         = each.value.password_auth_enabled
  }

  dynamic "customer_managed_key" {
    for_each = each.value.cmk_enabled && length(trim(each.value.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id = each.value.cmk_key_vault_key_id
    }
  }
}

# Legacy single-server support (backward compatibility)
resource "azurerm_postgresql_flexible_server" "postgresql_flexible_server" {
  count = (var.server_name != "") ? 1 : 0

  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  public_network_access_enabled = var.public_network_access_enabled
  zone                          = var.zone
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  storage_tier                  = var.storage_tier
  version                       = var.postgresql_version
  auto_grow_enabled             = var.auto_grow_enabled
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled

  authentication {
    active_directory_auth_enabled = var.active_directory_auth_enabled
    password_auth_enabled         = var.password_auth_enabled
  }
}