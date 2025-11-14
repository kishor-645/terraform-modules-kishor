variable "resource_group_name" {
  description = "The resource group name"
  type        = string
}

variable "location" {
  description = "The Azure Region"
  type        = string
}

variable "key_vault_name" {
  description = "The name of the vault"
  type        = string
}

variable "sku_name" {
  description = "The name of the sku"
  type = string
}

variable "public_network_access_enabled" {
  description = "Enable the public network access"
  type = bool
}

variable "soft_delete_retention_days" {
  description = "value"
  type = number
}

variable "purge_protection_enabled" {
  description = "value"
  type = bool
  default = true
}

# variable "aks_client_id" {
#   description = "AKS Client ID"
  
# }

# KV_ACCESS_POLICY

variable "key_vault_dependency" {
  description = "Dependency for the Key Vault resource"
  type        = list(any)
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

# variable "object_id" {
#   description = "Object ID for the principal"
#   type        = string
# }

# variable "key_permissions" {
#   description = "Permissions for keys"
#   type        = list(string)
#   default     = ["Get"]
# }

# variable "secret_permissions" {
#   description = "Permissions for secrets"
#   type        = list(string)
#   default     = ["Get"]
# }

# variable "certificate_permissions" {
#   description = "Permissions for certificates"
#   type        = list(string)
#   default     = ["Get"]
# }

variable "access_policies" {
  description = "List of access policies to be applied to the Key Vault."
  type = list(object({
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
  }))
}
