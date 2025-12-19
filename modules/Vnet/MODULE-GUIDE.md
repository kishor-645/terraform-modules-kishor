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

```hcl
module "vnet" {
  source = "../../modules/Vnet"

  # Use the main RG where VNet resides
  resource_group_name = var.rg
  location            = var.location

  vnets = {
    vnet-test-tf = {
      name = var.vnet
      address_space = ["10.0.0.0/16"]
      enable_ddos_protection = false
      subnets = {

        (var.private_endpoint_subnet) = {
          name           = var.private_endpoint_subnet
          address_prefix = "10.0.0.0/24"
        }
        (var.jumpbox_subnet) = {
          name           = var.jumpbox_subnet
          address_prefix = "10.0.1.0/24"
        }
        firewall = {
          name           = "AzureFirewallSubnet"
          address_prefix = "10.0.2.0/26"
        }
        (var.aks_subnet) = {
          name           = var.aks_subnet
          address_prefix = "10.0.100.0/22"
        
        }
        (var.agfc_subnet) = {
          name           = var.agfc_subnet
          address_prefix = "10.0.3.0/24"
          delegation = {
            name = var.agfc_subnet
            service_delegation = {
              name    = "Microsoft.ServiceNetworking/trafficControllers"
              actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
        }
      }
    }
  }
}
```


Notes
- Plan subnets sizes for expected scale; changing subnet CIDR requires recreate.
- Use subnet-level NSGs and Route Tables as needed.
