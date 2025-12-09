// acr_module/variables.tf

# ============================================================================
# MULTI-RESOURCE CONFIGURATION (Recommended)
# ============================================================================
variable "registries" {
  description = <<-EOT
    Map of Azure Container Registries to create. Each key is the registry name.
    Supports creating multiple registries with independent configuration in a single module call.
    
    Example:
    registries = {
      "prod-acr" = {
        resource_group_name         = "rg-prod"
        location                    = "eastus"
        sku                         = "Premium"
        admin_enabled               = false
        public_network_access_enabled = false
        cmk_enabled                 = true
        cmk_key_vault_key_id        = "/subscriptions/.../keys/acr-key"
        cmk_identity_id             = "/subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-identity"
        tags                        = { env = "prod", team = "platform" }
      }
    }
  EOT
  type = map(object({
    resource_group_name           = string
    location                      = string
    sku                           = optional(string, "Basic")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, false)
    cmk_enabled                   = optional(bool, false)
    cmk_key_vault_key_id          = optional(string, "")
    cmk_identity_id               = optional(string, "")
    tags                          = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Tags to apply to all registries."
  type        = map(string)
  default     = {}
}

# ============================================================================
# LEGACY SINGLE-RESOURCE CONFIGURATION (Deprecated - for backward compatibility)
# ============================================================================
variable "resource_group_name" {
  description = "(Deprecated) The name of the resource group. Use 'registries' map instead."
  type        = string
  default     = ""
}

variable "location" {
  description = "(Deprecated) The location of the resources. Use 'registries' map instead."
  type        = string
  default     = ""
}

variable "acr_name" {
  description = "(Deprecated) The name of the ACR. Use 'registries' map instead."
  type        = string
  default     = ""
}

variable "sku" {
  description = "(Deprecated) The SKU of the ACR. Use 'registries' map instead."
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "(Deprecated) Enable admin access to ACR. Use 'registries' map instead."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "(Deprecated) Enable public access to ACR. Use 'registries' map instead."
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Deprecated) Tags to apply to the ACR resource. Use 'registries' map instead."
  type        = map(string)
  default     = {}
}

variable "encryption_key_vault_key_id" {
  description = "(Deprecated) The resource ID of the Key Vault Key to use for customer-managed encryption (CMK). Use 'registries' map instead."
  type        = string
  default     = null
}

variable "encryption_identity_id" {
  description = "(Deprecated) The resource id of a user-assigned managed identity that has access to the key vault key. Use 'registries' map instead."
  type        = string
  default     = null
}
