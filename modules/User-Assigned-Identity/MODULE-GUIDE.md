User-Assigned Identity Module Guide

Purpose
- Create User Assigned Managed Identities (UAI) to attach to VMs, AKS, App Gateway, or other services.

Inputs
- `resource_group_name`, `location`
- `identities` (map): `name`, `tags`.

Outputs
- `identities` map with `client_id`, `principal_id`, and `id`.

Basic example
```hcl
module "uai" {
  source = "../../modules/User-Assigned-Identity"
  resource_group_name = "rg-shared"
  identities = { "uai-app" = { name = "uai-app" } }
}
```

Notes
- Reuse UAIs across services for least-privilege role assignments.
- Use `principal_id` when assigning RBAC roles.
