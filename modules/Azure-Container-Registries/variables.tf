// acr_module/variables.tf

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The location of the resources."
  type        = string
}

variable "acr_name" {
  description = "The name of the ACR."
  type        = string
}

variable "sku" {
  description = "The SKU of the ACR."
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Enable admin access to ACR."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public access to ACR."
  type = bool
  default = false
}

variable "tags" {
  description = "Tags to apply to the ACR resource."
  type        = map(string)
  default     = {}
}

variable "encryption_key_vault_key_id" {
  description = "(Optional) The resource ID of the Key Vault Key to use for customer-managed encryption (CMK). Provide null to skip CMK."
  type        = string
  default     = null
}

variable "encryption_identity_id" {
  description = "(Optional) The resource id of a user-assigned managed identity that has access to the key vault key. Provide null to skip setting an identity."
  type        = string
  default     = null
}
