# postgresql_flexible_server_module/main.tf
resource "azurerm_postgresql_flexible_server" "postgresql_flexible_server" {
  name                             = var.server_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  administrator_login              = var.admin_username
  administrator_password           = var.admin_password
  public_network_access_enabled    = var.public_network_access_enabled
  zone                             = var.zone
  sku_name                         = var.sku_name
  storage_mb                       = var.storage_mb
  storage_tier                     = var.storage_tier
  version                          = var.postgresql_version
  auto_grow_enabled                = var.auto_grow_enabled
  geo_redundant_backup_enabled     = var.geo_redundant_backup_enabled
 
  authentication {
    active_directory_auth_enabled = var.active_directory_auth_enabled
    password_auth_enabled         = var.password_auth_enabled 
    # tenant_id                     = var.tenant_id
  }
}

# resource "azurerm_postgresql_flexible_server_active_directory_administrator" "azure_postgresql_flexible_server_ad_administrator" {
#   server_name         = azurerm_postgresql_flexible_server.postgresql_flexible_server.name
#   resource_group_name = var.resource_group_name
#   tenant_id           = var.tenant_id
#   object_id           = var.object_id
#   principal_name      = var.principal_name
#   principal_type      = var.principal_type
# }
