variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "sku_name" {
  description = "SKU Name (e.g., GP_Standard_D2s_v3, B_Standard_B1ms)"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgresql_version" {
  description = "Version of PostgreSQL (12, 13, 14, 15, 16)"
  type        = string
  default     = "16"
}

# Storage
variable "storage_mb" {
  description = "Max storage allowed for a server (32768 MB = 32GB)"
  type        = number
  default     = 32768
}
variable "storage_tier" { default = "P30" }
variable "auto_grow_enabled" { default = true }

# Admin Auth
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}

# Reliability
variable "backup_retention_days" { default = 7 }
variable "geo_redundant_backup_enabled" { default = false }
variable "zone" { default = "1" }

variable "ha_mode" {
  description = "High Availability Mode: 'ZoneRedundant', 'SameZone', or null (Disabled)"
  type        = string
  default     = null
}
variable "standby_zone" {
  description = "Zone for the standby server (Required if ha_mode is set)"
  type        = string
  default     = "2"
}

# Identity & Security
variable "password_auth_enabled" { default = true }
variable "entra_auth_enabled" { default = false }
variable "tenant_id" { 
  description = "Tenant ID for Entra Auth (Required if enabled)"
  type        = string
  default     = null 
}

# CMK Configuration
variable "cmk_enabled" { default = false }
variable "cmk_key_vault_key_id" { default = null }
variable "cmk_user_assigned_identity_id" { default = null }
variable "identity_id" { 
  description = "Identity used for CMK access (User Assigned)"
  default = null 
}

# Networking
variable "public_network_access_enabled" {
  description = "Allow public access? Set to false if using Private Endpoints."
  type        = bool
  default     = false
}
variable "delegated_subnet_id" {
  description = "ID of delegated subnet. (For VNet Injection). Leave null for Private Endpoint mode."
  type        = string
  default     = null
}
variable "private_dns_zone_id" {
  description = "Private DNS Zone ID (For VNet Injection mode only)."
  type        = string
  default     = null
}

# Configuration
variable "server_parameters" {
  description = "Map of PostgreSQL parameters"
  type        = map(string)
  default     = {}
}

variable "tags" { default = {} }