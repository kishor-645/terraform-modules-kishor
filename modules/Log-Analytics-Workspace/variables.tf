variable "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU of the Log Analytics Workspace (Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Workspace data retention in days (30-730 days for PerGB2018)"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion limit in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation level (100, 200, 300, 400, 500, 1000, 2000, 5000) - Required for CapacityReservation SKU"
  type        = number
  default     = null
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (workspace keys)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the workspace"
  type        = map(string)
  default     = {}
}
