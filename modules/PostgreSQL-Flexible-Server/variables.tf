variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location where resources will be created"
  type        = string
}

variable "postgresql_servers" {
  description = "Map of PostgreSQL Flexible Servers to create. Each server can have independent configuration."
  type = map(object({
    sku_name                       = string
    storage_mb                     = number
    admin_username                 = string
    admin_password                 = string
    postgresql_version             = optional(string, "14")
    zone                           = optional(string, "1")
    storage_tier                   = optional(string, "P30")
    public_network_access_enabled  = optional(bool, false)
    auto_grow_enabled              = optional(bool, true)
    geo_redundant_backup_enabled   = optional(bool, true)
    active_directory_auth_enabled  = optional(bool, false)
    password_auth_enabled          = optional(bool, true)
    cmk_enabled                    = optional(bool, false)
    cmk_key_vault_key_id           = optional(string, "")
    cmk_user_assigned_identity_id  = optional(string, "")
    tags                           = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all PostgreSQL servers"
  type        = map(string)
  default     = {}
}

# Legacy single-server inputs (deprecated)
variable "server_name" {
  description = "(Deprecated) Use postgresql_servers map instead"
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "(Deprecated) Use postgresql_servers map instead"
  type        = string
  default     = ""
}

variable "admin_password" {
  description = "(Deprecated) Use postgresql_servers map instead"
  type        = string
  sensitive   = true
  default     = ""
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = true
}

variable "zone" {
  description = "The availability zone for the PostgreSQL server"
  type        = string
  default     = "1"
}

variable "sku_name" {
  description = "The SKU for the PostgreSQL server"
  type        = string
}

variable "storage_mb" {
  description = "The storage size for the PostgreSQL server in MB"
  type        = number
}

variable "storage_tier" {
  description = "The storage tier"
  type        = string
  default     = "P30"
}

variable "cmk_enabled" {
  description = "Enable customer-managed key (CMK) for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "cmk_key_vault_key_id" {
  description = "Full resource id of the Key Vault Key to use as CMK for PostgreSQL. If empty CMK is not applied."
  type        = string
  default     = ""
}

variable "cmk_user_assigned_identity_id" {
  description = "Optional user assigned identity id that has unwrapKey permissions on the Key Vault key"
  type        = string
  default     = ""
}

variable "postgresql_version" {
  description = "The PostgreSQL version"
  type        = string
}

variable "auto_grow_enabled" {
  description = "Whether auto grow is enabled"
  type        = bool
  default     = true
}

variable "geo_redundant_backup_enabled" {
  description = "Enable or disable GeoRedundant backups"
  type        = bool
  default     = true
}

variable "active_directory_auth_enabled" {
  description = "Whether Active Directory Authentication is enabled"
  type        = bool
  default     = true
}

variable "password_auth_enabled" {
  description = "Whether password authentication is enabled"
  type        = bool
  default     = true
}

# variable "tenant_id" {
#   description = "The tenant ID for Active Directory"
#   type        = string
# }

# variable "object_id" {
#   description = "The object ID of the AD administrator"
#   type        = string
# }

# variable "principal_name" {
#   description = "The principal name of the AD administrator"
#   type        = string
# }

# variable "principal_type" {
#   description = "The principal type of the AD administrator"
#   type        = string
#   default     = "Group"
# }
