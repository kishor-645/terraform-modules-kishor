
resource "azurerm_key_vault_access_policy" "kv_policy" {
  for_each                = { for idx, policy in var.access_policies : idx => policy }
  depends_on              = [var.key_vault_dependency]
  key_vault_id            = var.key_vault_id
  tenant_id               = var.tenant_id
  object_id               = each.value.object_id
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
}