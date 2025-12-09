Azure Front Door Module Guide

Purpose
- Create and manage Azure Front Door (AFD) resources: profile, endpoints, origin groups, routes.
- Supports multi-origin, caching and WAF integration.

Inputs
- `resource_group_name`, `location`
- `frontdoors` (map): each entry may include `name`, `routing_rules`, `origin_groups`, `custom_domains`, `waf_policy`.

Outputs
- `frontdoor_endpoints` map (endpoint URL, id).

Basic example
```hcl
module "afd" {
  source = "../../modules/Azure-Frontdoor"
  resource_group_name = "rg-global"
  frontdoors = {
    "afd-main" = {
      name = "afd-main"
      origin_groups = {
        backend = { origins = [azurerm_public_ip.web.ip_address] }
      }
      routing_rules = { default = { route_type = "Forward" } }
    }
  }
}
```

Notes
- Use Front Door for global routing, lower latency, and WAF attachment at edge.
- Combine with origin health probes for reliability.
