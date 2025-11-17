resource "azurerm_log_analytics_workspace" "this" {
  name                               = var.workspace_name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  sku                                = var.sku
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day
  local_authentication_disabled      = var.local_authentication_disabled
  tags                               = var.tags
}
