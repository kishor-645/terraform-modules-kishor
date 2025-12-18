resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgresql_version
  sku_name            = var.sku_name
  
  # Storage
  storage_mb   = var.storage_mb
  storage_tier = var.storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  # Admin Login
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  # Backup & Reliability
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  zone                         = var.zone

  # High Availability (Optional)
  dynamic "high_availability" {
    for_each = var.ha_mode != null ? [1] : []
    content {
      mode                      = var.ha_mode
      standby_availability_zone = var.standby_zone
    }
  }

  # Authentication
  authentication {
    active_directory_auth_enabled = var.entra_auth_enabled
    password_auth_enabled         = var.password_auth_enabled
    tenant_id                     = var.entra_auth_enabled ? var.tenant_id : null
  }

  # Customer Managed Key (CMK)
  dynamic "customer_managed_key" {
    for_each = var.cmk_enabled ? [1] : []
    content {
      key_vault_key_id                  = var.cmk_key_vault_key_id
      primary_user_assigned_identity_id = var.cmk_user_assigned_identity_id
    }
  }

  # Identity (Required for CMK)
  dynamic "identity" {
    for_each = var.identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.identity_id]
    }
  }

  # Network
  # NOTE: If using Private Endpoints, leave delegated_subnet_id as null
  # and set public_network_access_enabled to false.
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# Configuration settings (Parameters)
resource "azurerm_postgresql_flexible_server_configuration" "params" {
  for_each = var.server_parameters

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value
}