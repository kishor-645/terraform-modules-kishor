variable "resource_group_name" {
  description = "The resource group name. Module-level default used by vaults unless overridden per-vault."
  type        = string
}

variable "location" {
  description = "The Azure Region. Module-level default used by vaults unless overridden per-vault."
  type        = string
}

variable "key_vaults" {
  description = "Map of Key Vaults to create. Each vault can have its own SKU and configuration."
  type = map(object({
    sku_name                      = optional(string, "standard")
    public_network_access_enabled = optional(bool, false)
    soft_delete_retention_days    = optional(number, 90)
    purge_protection_enabled      = optional(bool, true)
    tags                          = optional(map(string), {})
    # Per-vault location and resource group removed to simplify module.
    # Provide module-level `resource_group_name` and `location` instead (via tfvars
    # or the module call). If you need per-vault overrides, open an issue and
    # we can reintroduce them on demand.
    # auth_type: "access_policy" or "rbac". If omitted, falls back to module var `default_auth_type`.
    auth_type                     = optional(string)
    # Optional per-vault access policies when using access_policy auth_type
    access_policies               = optional(list(object({
      object_id               = string
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      certificate_permissions = optional(list(string), [])
    })), [])
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all key vaults"
  type        = map(string)
  default     = {}
}
# Choose default auth type when not set per-vault: "access_policy" or "rbac"
variable "default_auth_type" {
  description = "Default authorization type for Key Vaults when per-vault `auth_type` is not set. Valid values: 'access_policy' or 'rbac'."
  type        = string
  default     = "access_policy"
}

# Legacy single-vault variables removed. This module now manages one or more
# vaults via the `key_vaults` map and reads `tenant_id` from the data source.
