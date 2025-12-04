variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The name of the location"
  type        = string
}

variable "account_tier" {
  description = "The name of the account tier"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The name of the account replication type"
  type        = string
  default     = "LRS"
}

variable "public_network_access_enabled" {
  description = "Enable or Disable the public network access"
  type = bool
}

variable "infrastructure_encryption_enabled"{
  description = "Enable or Disable the Infrastructure Encryption"
  type = bool
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
