Private DNS Zone Module Guide

Purpose
- Create Private DNS Zones and records, and link them to Virtual Networks.

Inputs
- `resource_group_name`, `location`
- `private_dns_zones` (map): `zone_name`, `records` (map of A/CNAME/TXT), `vnet_link_ids`.

Outputs
- `private_dns_zones` map with `id`, `zone_name`.

Basic example
```hcl
module "pdns" {
  source = "../../modules/Private-DNS-Zone"
  resource_group_name = "rg-network"
  private_dns_zones = {
    "zone01" = { zone_name = "privatelink.database.windows.net", records = { "pg" = { type = "A", value = "10.0.0.10" } } }
  }
}
```

Notes
- Use zone linking to ensure VMs/AKS nodes can resolve private endpoints.
- Manage records centrally to avoid duplication across environments.
