variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "key_vault_key_id" { 
  description = "The URL of the Key Vault Key"
  type        = string 
}

variable "identity_id" {
  description = "Resource ID of the User Assigned Identity. Leave null for SystemAssigned."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable auto_key_rotation_enabled {
 type = bool
 default = false
}

