variable "identities" {
  description = "Map of user assigned identities to create. Keyed by a unique name. Example: app => { name = \"app-uai\" resource_group = \"rg\" location = \"eastus\" }"
  type = map(object({
    name           = string
    resource_group = string
    location       = string
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "role_assignments" {
  description = "Map of role assignments to create. Keyed by a unique id. Example: assign1 => { principal_id = \"<principal-id>\" role_definition_name = \"Contributor\" scope = \"/subscriptions/...\" }"
  type = map(object({
    principal_id         = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    scope                = string
  }))
  default = {}
}
