VNet Peering Module Guide

Purpose
- Create VNet peering connections between VNets (same or different subscription) and optionally configure gateway transit.

Inputs
- `resource_group_name`, `location`
- `peerings` (map): `name`, `remote_vnet_id`, `allow_forwarded_traffic`, `allow_gateway_transit`, `use_remote_gateways`.

Outputs
- `peerings` map with `id` and `peering_status`.

Basic example
```hcl
module "peering" {
  source = "../../modules/Vnet-peering"
  resource_group_name = "rg-network"
  peerings = {
    "vnet-a-to-b" = { name = "a-to-b", remote_vnet_id = module.vnet_b.vnets["vnet-b"].id }
  }
}
```

Notes
- For cross-subscription peering, ensure proper RBAC permissions.
- Gateway transit allows shared VPN/ExpressRoute gateways.
