variable "resource_groups" {
  description = "Map of resource groups to create. Keyed by a unique name. Each RG can have its own location and tags."
  type = map(object({
    location = string
    tags     = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resource groups"
  type        = map(string)
  default     = {}
}

# Legacy single-RG inputs (deprecated, kept for backward compatibility)
variable "resource_group_name" {
  description = "(Deprecated) The name of a single resource group. Use `resource_groups` map instead."
  type        = string
  default     = ""
}

variable "location" {
  description = "(Deprecated) The location/region. Use `resource_groups` map instead."
  type        = string
  default     = ""
}
