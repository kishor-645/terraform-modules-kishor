# postgresql_flexible_server_module/variables.tf
variable "server_name" {
  description = "The name of the PostgreSQL Flexible Server"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location where the resource will be created"
  type        = string
}

variable "admin_username" {
  description = "The admin username for the PostgreSQL server"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the PostgreSQL server"
  type        = string
  sensitive   = true
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
