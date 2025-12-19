# --- Core Identity ---
variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "postgresql_version" {
  description = "Version: 12, 13, 14, 15, 16"
  default     = "16"
}

# --- Compute & Storage (Matches Portal Screenshot Defaults) ---
variable "sku_name" {
  description = "SKU Name (e.g., GP_Standard_D2s_v3)"
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  description = "Storage in MB (32768 = 32GB)"
  type        = number
  default     = 32768
}

variable "storage_tier" { default = "P10" } # Default per your screenshot P4 (120 iops)
variable "auto_grow_enabled" { default = true }

# --- High Availability ---
variable "ha_mode" {
  description = "HA Mode: 'ZoneRedundant', 'SameZone', or null (Disabled)"
  default     = null 
}
variable "zone" { default = "1" }
variable "standby_zone" { default = "2" }

variable "backup_retention_days" { default = 7 }
variable "geo_redundant_backup_enabled" { default = false }

# --- Security: Admin ---
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}

# --- Security: CMK ---
variable "cmk_enabled" {
  type    = bool
  default = false
}
variable "cmk_key_vault_key_id" {
  description = "Key URL/ID from Key Vault. Required if cmk_enabled = true."
  type        = string
  default     = null
}
variable "cmk_identity_id" {
  description = "The User Assigned Identity ID that has access to the Key."
  type        = string
  default     = null
}

# --- Auth & Access ---
variable "password_auth_enabled" { default = true }
variable "entra_auth_enabled" { default = false }
variable "tenant_id" { default = null }

# --- Network ---
variable "public_network_access_enabled" {
  description = "Enable Public Access. Set false if using Private Endpoint."
  type        = bool
  default     = false
}
variable "delegated_subnet_id" {
  description = "Only if VNET INJECTION used. Otherwise null."
  default     = null
}
variable "private_dns_zone_id" {
  description = "Only if VNET INJECTION used. Otherwise null."
  default     = null
}

variable "tags" { 
  type    = map(string)
  default = {} 
}

variable "server_parameters" {
  type    = map(string)
  default = {}
}