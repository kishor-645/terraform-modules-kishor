Log Analytics Workspace Module Guide

Purpose
- Create Log Analytics Workspaces and optionally configure data sources (VMs, diagnostics).

Inputs
- `resource_group_name`, `location`
- `workspaces` (map): `name`, `sku`, `retention_days`, `linked_resources`.

Outputs
- `workspaces` map with `id`, `primary_shared_key`, and `workspace_id`.

Basic example
```hcl
module "law" {
  source = "../../modules/Log-Analytics-Workspace"
  resource_group_name = "rg-monitor"
  workspaces = { "law-prod" = { name = "law-prod", sku = "PerGB2018", retention_days = 30 } }
}
```

Notes
- Use the workspace id and key to configure diagnostics or agents.
- For production, set retention_days and upload capacity accordingly.
