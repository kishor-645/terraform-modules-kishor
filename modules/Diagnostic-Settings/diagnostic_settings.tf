resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = var.diagnostic_setting_name
  target_resource_id             = var.target_resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  storage_account_id             = var.storage_account_id
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  eventhub_name                  = var.eventhub_name
  log_analytics_destination_type = var.log_analytics_destination_type

  # Dynamic enabled logs
  dynamic "enabled_log" {
    for_each = var.enabled_logs
    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  # Dynamic metrics
  dynamic "metric" {
    for_each = var.enabled_metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}
