resource "random_uuid" "ra" {
  for_each = var.role_assignments
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  name         = random_uuid.ra[each.key].result
  scope        = each.value.scope
  principal_id = each.value.principal_id
  role_definition_id   = lookup(each.value, "role_definition_id", null)
  role_definition_name = lookup(each.value, "role_definition_name", null)
}
