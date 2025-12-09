Role Assignment Module Guide

Purpose
- Assign Azure RBAC roles (subscription/resource group/resource) to principals (user, service principal, managed identity) in a repeatable manner.

Inputs
- `role_assignments` (map): `name`, `role_definition_name` or `role_definition_id`, `principal_id`, `scope` (resource id).

Outputs
- `role_assignment_ids` map with created assignment ids.

Basic example
```hcl
module "ra" {
  source = "../../modules/Role-Assignment"
  role_assignments = {
    "aks-cmk-kv-crypto" = {
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id = module.kv_premium_cmk.kv_service_principal_object_id
      scope = module.kv_premium_cmk.key_vaults["tf-cmk-vault-test"].id
    }
  }
}
```

Notes
- Use `principal_id` that references the correct managed identity or SP object id.
- Role assignments may take time to propagate; consider retry logic in automation.
