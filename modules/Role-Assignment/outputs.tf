output "role_assignment_ids" {
  description = "Map of created role assignment resource ids"
  value = { for k, v in azurerm_role_assignment.this : k => v.id }
}
