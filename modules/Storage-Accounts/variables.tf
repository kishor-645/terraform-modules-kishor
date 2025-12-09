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
