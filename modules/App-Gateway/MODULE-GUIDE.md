Application Gateway Module Guide

Purpose
- Create/manage Azure Application Gateway instances (v2), including WAF policy attachment, frontend IPs, listeners, and backend pools.
- Designed to be used for simple and advanced scenarios (single app gateway, multi-site, WAF-enabled).

Inputs (high level)
- `resource_group_name` (string)
- `location` (string)
- `app_gateways` (map(object))
  - `name`, `sku`, `tier` (Standard_v2/WAF_v2), `frontend_public_ip_id`, `subnet_id`, `waf_policy_id`
- `common_tags` (map)

Outputs
- `app_gateways` map with `id`, `frontend_ip`, and `resource_name`.

Basic example
```hcl
module "appgw" {
  source = "../../modules/App-Gateway"
  resource_group_name = "rg-prod"
  location = "uksouth"
  app_gateways = {
    "appgw-main" = {
      name = "appgw-main"
      sku  = "WAF_v2"
      subnet_id = var.subnet_appgw
      frontend_public_ip_id = azurerm_public_ip.appgw_pip.id
    }
  }
}
```

Multi-site example (multiple listeners/backends)
```hcl
module "appgw_multi" {
  source = "../../modules/App-Gateway"
  resource_group_name = "rg-prod"
  app_gateways = {
    "appgw-site1" = { name = "appgw-site1", subnet_id = var.subnet_appgw }
  }
  # define backend configs in the app_gateways map per gateway
}
```

Notes
- For WAF, set `sku = "WAF_v2"` and optionally pass `waf_policy_id`.
- Use managed identities for backend HTTP settings when needed.
