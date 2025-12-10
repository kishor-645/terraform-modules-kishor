data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name = each.key

  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name = try(each.value.sku_name, "standard")

  public_network_access_enabled = try(each.value.public_network_access_enabled, false)
  soft_delete_retention_days    = try(each.value.soft_delete_retention_days, 90)
  purge_protection_enabled      = try(each.value.purge_protection_enabled, true)
  tags = merge(try(each.value.tags, {}), var.common_tags)

  # Determine effective auth type: per-vault override -> module default
    rbac_authorization_enabled = (try(each.value.auth_type, var.default_auth_type) == "rbac")

  # When using access_policy auth model, apply access_policy blocks per vault
  dynamic "access_policy" {
    for_each = (try(each.value.auth_type, var.default_auth_type) == "access_policy") ? try(each.value.access_policies, []) : []
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      key_permissions         = try(access_policy.value.key_permissions, [])
      secret_permissions      = try(access_policy.value.secret_permissions, [])
      certificate_permissions = try(access_policy.value.certificate_permissions, [])
    }
  }
}