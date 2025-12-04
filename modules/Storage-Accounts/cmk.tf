/*
  NOTE: CMK integration for Storage Accounts is handled inline in `storage_accounts.tf`
  via a dynamic `customer_managed_key` block. This file used to contain a separate
  resource but has been replaced with that approach to keep the resource declaration
  in one place.

  To enable CMK for this module, set variables:
    - `cmk_enabled = true`
    - `cmk_key_vault_key_id = "<full-key-resource-id>"`
    - `cmk_user_assigned_identity_id` (optional) - UAI that can unwrap the key

  The module will add the `customer_managed_key` block to the `azurerm_storage_account`
  only when `cmk_enabled` is true and a non-empty `cmk_key_vault_key_id` is provided.
*/

