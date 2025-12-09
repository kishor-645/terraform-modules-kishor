variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The name of the location"
  type        = string
}

variable "storage_accounts" {
  description = "Map of storage accounts to create. Each account can have its own tier, replication, and CMK settings."
  type = map(object({
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "LRS")
    public_network_access_enabled     = optional(bool, false)
    infrastructure_encryption_enabled = optional(bool, false)
    cmk_enabled                       = optional(bool, false)
    cmk_key_vault_key_id              = optional(string, "")
    cmk_user_assigned_identity_id     = optional(string, "")
    tags                              = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all storage accounts"
  type        = map(string)
  default     = {}
}

# Legacy single-storage inputs (deprecated)
variable "storage_account_name" {
  description = "(Deprecated) Use storage_accounts map instead"
  type        = string
  default     = ""
}

variable "account_tier" {
  description = "(Deprecated) Use storage_accounts map instead"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "(Deprecated) Use storage_accounts map instead"
  type        = string
  default     = "LRS"
}

variable "public_network_access_enabled" {
  description = "(Deprecated) Use storage_accounts map instead"
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "(Deprecated) Use storage_accounts map instead"
  type        = bool
  default     = false
}

variable "cmk_enabled" {
  description = "Enable customer-managed key (CMK) for this storage account"
  type        = bool
  default     = false
}

variable "cmk_key_vault_key_id" {
  description = "Full resource id of the Key Vault Key to use as CMK. If empty CMK is not applied."
  type        = string
  default     = ""
}

variable "cmk_user_assigned_identity_id" {
  description = "Optional user assigned identity id that has unwrapKey permissions on the Key Vault key"
  type        = string
  default     = ""
}
