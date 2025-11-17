variable "diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  type        = string
}

variable "target_resource_id" {
  description = "ID of the target resource to enable diagnostics on"
  type        = string
}

# Destination Variables
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Storage Account ID for long-term retention"
  type        = string
  default     = null
}

variable "eventhub_authorization_rule_id" {
  description = "Event Hub Authorization Rule ID"
  type        = string
  default     = null
}

variable "eventhub_name" {
  description = "Event Hub Name"
  type        = string
  default     = null
}

variable "log_analytics_destination_type" {
  description = "Log Analytics destination type (Dedicated or AzureDiagnostics)"
  type        = string
  default     = null
}

# Logs Configuration
variable "enabled_logs" {
  description = "List of log categories to enable"
  type = list(object({
    category       = optional(string)
    category_group = optional(string)
  }))
  default = []
}

# Metrics Configuration
variable "enabled_metrics" {
  description = "List of metrics to enable"
  type = list(object({
    category = string
    enabled  = bool
  }))
  default = []
}
