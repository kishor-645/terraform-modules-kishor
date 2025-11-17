output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.name
}
