variable "role_assignments" {
  description = "Map of role assignments to create. Keyed by unique id. Example: id1 => { principal_id = \"<id>\" role_definition_name = \"Contributor\" scope = \"<scope>\" }"
  type = map(object({
    principal_id         = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    scope                = string
  }))
  default = {}
}
