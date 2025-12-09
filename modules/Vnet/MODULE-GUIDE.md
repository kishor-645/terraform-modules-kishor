VNet Module Guide

Purpose
- Create Virtual Networks and subnets with optional DDoS, NSGs, and service endpoints.

Inputs
- `resource_group_name`, `location`
- `vnets` (map): each vnet includes `name`, `address_space`, `subnets` (map of subnet definitions), `enable_ddos_protection`.

Outputs
- `vnets` map with `id`, `subnet_ids` map.

Basic example
```hcl
module "vnet" {
  source = "../../modules/Vnet"
  resource_group_name = "rg-network"
  vnets = {
    "vnet-prod" = {
      name = "vnet-prod"
      address_space = ["10.0.0.0/16"]
      subnets = { app = { name = "app", address_prefix = "10.0.1.0/24" } }
    }
  }
}
```

Notes
- Plan subnets sizes for expected scale; changing subnet CIDR requires recreate.
- Use subnet-level NSGs and Route Tables as needed.
