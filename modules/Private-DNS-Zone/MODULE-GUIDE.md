# Module Guide: Private DNS Zones

## **Overview**
**Directory:** `modules/Private-DNS-Zones`

This module allows you to create one or multiple **Azure Private DNS Zones** simultaneously. It effectively manages the "split-horizon" DNS resolution required for Private Endpoints. Additionally, it handles the **Virtual Network Links**, allowing you to automatically register or resolve DNS records from specific VNets (e.g., Hub, Prod, Dev).

### **Key Features**
*   **Bulk Creation:** Create lists of zones (Blob, KeyVault, SQL, etc.) in a single block.
*   **Bulk Linking:** Link the created zones to one or multiple Virtual Networks automatically.
*   **Clean Outputs:** Returns a map of Zone Names to IDs for easy reference by the Private Endpoint module.

## **Input Variables**

| Variable | Type | Description |
| :--- | :--- | :--- |
| `resource_group_name` | string | The Resource Group where the Zones will live. |
| `dns_zone_names` | list(string) | A list of zone names to create. |
| `vnet_ids_to_link` | map(string) | A map of `Name -> ID` for VNets that need to resolve these zones. |
| `tags` | map | Tags for the resources. |

---

## **Usage Examples**

### **Scenario A: Standard PaaS Zones (Single VNet)**
*Create standard Azure zones for Storage and KeyVault, linking them to a single VNet.*

```hcl
module "private_dns" {
  source              = "./modules/Private-DNS-Zones"
  resource_group_name = "rg-shared-network"

  # List of zones required for your Private Endpoints
  dns_zone_names = [
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurecr.io"
  ]

  # Link these to your main VNet
  vnet_ids_to_link = {
    "vnet-prod" = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-prod"
  }
}
```

### **Scenario B: Hub & Spoke Topology (Multiple Links)**
*Create zones and link them to the Hub (for VPN users) and multiple Spokes (for workloads).*

```hcl
module "platform_dns" {
  source              = "./modules/Private-DNS-Zones"
  resource_group_name = "rg-hub-connectivity"

  dns_zone_names = [
    "privatelink.postgres.database.azure.com",
    "privatelink.redis.cache.windows.net"
  ]

  vnet_ids_to_link = {
    "vnet-hub"  = module.hub_network.vnet_id
    "vnet-prod" = module.prod_network.vnet_id
    "vnet-dev"  = module.dev_network.vnet_id
  }
}
```

### **Scenario C: Custom Domain Zone**
*Create a specific internal domain for custom VM DNS resolution.*

```hcl
module "internal_dns" {
  source              = "./modules/Private-DNS-Zones"
  resource_group_name = "rg-app-core"

  dns_zone_names = ["internal.corp.local"]

  vnet_ids_to_link = {
    "vnet-prod" = module.vnet.vnet_id
  }
}
```