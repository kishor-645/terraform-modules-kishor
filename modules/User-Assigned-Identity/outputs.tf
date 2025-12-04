output "identities" {
  description = "Map of created user assigned identities with their ids and principal ids"
  value = { for k, v in azurerm_user_assigned_identity.this : k => {
    id = v.id
    client_id = v.client_id
    principal_id = v.principal_id
    name = v.name
  } }
}

output "role_assignment_ids" {
  description = "Map of role assignment ids created"
  value = { for k, v in azurerm_role_assignment.this : k => v.id }
}
