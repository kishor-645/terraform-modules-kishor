/*
  PostgreSQL Flexible Server CMK guidance

  Many azurerm provider versions support a `customer_managed_key` block within
  the `azurerm_postgresql_flexible_server` resource. Because this module defines
  the server in `main.tf`, we provide the example below to show the minimal
  changes required to enable CMK when `var.cmk_enabled` is true and a
  `var.cmk_key_vault_key_id` is supplied.

  Example (inside the existing `azurerm_postgresql_flexible_server` resource):

  dynamic "customer_managed_key" {
    for_each = var.cmk_enabled && length(trim(var.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id = var.cmk_key_vault_key_id
      user_assigned_identity_id = length(trim(var.cmk_user_assigned_identity_id)) > 0 ? var.cmk_user_assigned_identity_id : null
    }
  }

  Notes:
  - If your provider version supports a separate resource for CMK, you can
    create that resource instead; otherwise the dynamic block above is the
    simplest, least-invasive approach.
  - Ensure the identity used has `unwrapKey` and `get` permissions on the Key Vault key.
*/
