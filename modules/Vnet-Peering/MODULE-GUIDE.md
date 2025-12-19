### MODULE-GUIDE.md

Here is the documentation you requested.

---

# VNet Peering Module Guide

## Overview
**Directory:** `modules/Vnet-Peering`

This module manages the relationship between two Virtual Networks. In Azure, for a connection to work, it must be created in **both directions** (A→B and B→A). This module handles both sides in a single configuration block, even if the VNets exist in different Resource Groups.

## Usage Examples

### Scenario 1: Standard Connectivity (Simple Mesh)
Connecting two Spoke networks (e.g., Prod to Dev for tooling) directly. No VPN Gateways involved.

```hcl
module "peering_spokes" {
  source = "./modules/Vnet-Peering"

  peerings = {
    "prod-to-dev" = {
      # Source (Prod)
      vnet_a_name = "vnet-prod"
      vnet_a_id   = module.vnet_prod.id
      vnet_a_rg   = "rg-prod"

      # Destination (Dev)
      vnet_b_name = "vnet-dev"
      vnet_b_id   = module.vnet_dev.id
      vnet_b_rg   = "rg-dev"
    }
  }
}
```

### Scenario 2: Hub & Spoke (VPN Gateway Integration)
**This is the most critical use case.**
*   **Hub:** Has a VPN Gateway. Must **Allow** gateway transit.
*   **Spoke:** Has no gateway. Must **Use** remote gateways to reach on-premise/internet.

```hcl
module "peering_hub_spoke" {
  source = "./modules/Vnet-Peering"

  peerings = {
    "hub-to-aks" = {
      # --- HUB SIDE (A) ---
      vnet_a_name = "vnet-hub"
      vnet_a_id   = module.vnet_hub.id
      vnet_a_rg   = "rg-hub"
      
      # The Hub has the VPN, so it allows transit
      vnet_a_allow_gateway_transit = true 
      vnet_a_use_remote_gateways   = false

      # --- SPOKE SIDE (B) ---
      vnet_b_name = "vnet-aks-spoke"
      vnet_b_id   = module.vnet_aks.id
      vnet_b_rg   = "rg-aks"
      
      # The Spoke uses the Hub's VPN
      vnet_b_allow_gateway_transit = false
      vnet_b_use_remote_gateways   = true 
    }
  }
}
```

### Critical Requirements
1.  **Permissions:** The Service Principal running Terraform must have `Network Contributor` rights on **both** Resource Groups if they are different.
2.  **No Overlap:** The IP Address spaces of the two VNets **cannot overlap**. Terraform will return an error if they do.
3.  **Gateway Transit:** You cannot set `use_remote_gateways` to `true` if the remote VNet does not actually have a VPN/ExpressRoute Gateway active. Azure API will fail.