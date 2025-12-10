### Directory Structure
```
modules/
└── AKS-Private-Cluster/
    ├── main.tf                 # Cluster and User Node Pools
    ├── security.tf             # Disk Encryption Sets (CMK)
    ├── rbac.tf                 # Built-in Role Assignments (Optional)
    ├── variables.tf
    ├── output.tf
    └── AKS-MODULE-GUIDE.md     # The Documentation
```

## AKS Module Guide

This module deploys highly secure, private Azure Kubernetes Service (AKS) clusters. It is designed for multi-environment use (Prod/Dev/UAT) using dynamic maps.

### Features
*   **CMK (Customer Managed Keys):** Integrated logic to create Disk Encryption Sets automatically.
*   **Auto Scaling:** Built-in configuration for Cluster Autoscaler.
*   **RBAC:** Automates Subnet Network Contributor assignment.
*   **Flexible Identity:** Supports both SystemAssigned and UserAssigned identities.

### Input Variable: `aks_clusters` (Map)
The core input. Each key is the cluster name.

| Field | Description | Default |
| :--- | :--- | :--- |
| `vnet_subnet_id` | **Required.** The subnet resource ID for the nodes. | - |
| `private_cluster_enabled` | Boolean. Set true for prod. | `true` |
| `sku_tier` | `Standard` (Prod) or `Free` (Dev). | `Standard` |
| `cmk_enabled` | Enable Disk Encryption Set creation. | `false` |
| `cmk_key_vault_key_id` | Full ID of the Key Vault Key. Required if `cmk_enabled=true`. | - |
| `user_assigned_identity_id` | ID of the identity (optional, highly recommended for prod). | `null` |

---

### Usage Example: Development (Simple, No CMK)

```hcl
module "aks_dev" {
  source              = "./modules/AKS-Private-Cluster"
  resource_group_name = "rg-dev-aks"
  location            = "eastus"

  aks_clusters = {
    "aks-dev-01" = {
      dns_prefix         = "aksdev"
      sku_tier           = "Free"
      vnet_subnet_id     = module.vnet.subnet_ids["aks-subnet"]
      default_node_pool  = {
         name = "agentpool"
         node_count = 2 
         auto_scaling_enabled = false
      }
    }
  }
}
```

### Usage Example: Production (CMK, Autoscaling, User Identity)

```hcl
module "aks_prod" {
  source              = "./modules/AKS-Private-Cluster"
  resource_group_name = "rg-prod-aks"
  location            = "eastus"

  aks_clusters = {
    "aks-prod-erp" = {
      dns_prefix              = "akserp"
      sku_tier                = "Standard"
      private_cluster_enabled = true
      
      # Identity
      identity_type             = "UserAssigned"
      user_assigned_identity_id = module.uai.identities["aks-identity"].id

      # CMK Encryption
      cmk_enabled          = true
      cmk_key_vault_key_id = azurerm_key_vault_key.des_key.id
      des_identity_id      = module.uai.identities["des-identity"].id

      # Network
      vnet_subnet_id = module.vnet.subnet_ids["aks-nodes-subnet"]

      default_node_pool = {
         name       = "systempool"
         vm_size    = "Standard_D4s_v3"
         auto_scaling_enabled = true
         min_count  = 2
         max_count  = 5
         zones      = ["1", "2", "3"]
      }
    }
  }
}
```

### Usage Example: Adding an extra User Node Pool

To add heavy-duty nodes (e.g., Memory optimized) to the Production cluster above:

```hcl
node_pools = {
  "erp-memory-pool" = {
    cluster_name      = "aks-prod-erp" # Matches the key in aks_clusters
    name              = "mempool"
    vm_size           = "Standard_E4s_v3"
    node_count        = 2
    auto_scaling_enabled = true
    max_count         = 10
  }
}
```