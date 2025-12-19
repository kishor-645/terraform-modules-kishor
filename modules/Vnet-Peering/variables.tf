variable "peerings" {
  description = "Map of VNet peering configurations. Defines a bidirectional link between VNet A and VNet B."
  type = map(object({
    # VNet A Details (Source side)
    vnet_a_name = string
    vnet_a_id   = string
    vnet_a_rg   = string # Resource Group of VNet A

    # VNet B Details (Remote side)
    vnet_b_name = string
    vnet_b_id   = string
    vnet_b_rg   = string # Resource Group of VNet B

    # Global Options (Applied to both directions)
    allow_vnet_access       = optional(bool, true) # Usually true to allow comms
    allow_forwarded_traffic = optional(bool, true) # Important for Hub/Spoke traffic flow

    # VNet A Gateway Options
    vnet_a_allow_gateway_transit = optional(bool, false)
    vnet_a_use_remote_gateways   = optional(bool, false)

    # VNet B Gateway Options
    vnet_b_allow_gateway_transit = optional(bool, false)
    vnet_b_use_remote_gateways   = optional(bool, false)
  }))
  default = {}
}