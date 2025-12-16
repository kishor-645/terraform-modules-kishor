# Module Guide: Private Endpoints

## **Overview**
**Directory:** `modules/Private-Endpoints`

This module acts as a "Generic Factory" for Azure Private Endpoints. It attaches to **any** Azure Resource (PaaS) supported by Private Link (Storage, SQL, KeyVault, AKS, App Service, etc.). It also automatically groups the endpoint with the relevant Private DNS Zone to ensure name resolution works.

### **Key Features**
*   **Resource Agnostic:** Not limited to specific resources; works by passing the Resource ID.
*   **Dynamic DNS:** Optionally links to Private DNS Zones.
*   **Flexible Subnets:** Different endpoints within the same module call can sit in different subnets.

## **Input Variables**

| Variable | Type | Description |
| :--- | :--- | :--- |
| `resource_group_name` | string | The RG where the Endpoint Network Interfaces will be created. |
| `location` | string | Azure Region. |
| `private_endpoints` | map | Complex object defining the resources to connect. |

### **`private_endpoints` Map Structure**
Each key in the map requires:
*   `subnet_id`: ID of the Subnet where the endpoint IP is allocated.
*   `private_connection_resource_id`: The ID of the Azure Resource (e.g., Storage Account ID).
*   `subresource_names`: The "target subresource" (e.g., `blob`, `file`, `vault`, `registry`, `sqlServer`).
*   `private_dns_zone_ids`: A list of DNS Zone IDs to register the IP in.

## **Usage Examples**

### **Common Subresource Reference**
*   **Storage (Blob):** `["blob"]`
*   **Storage (File):** `["file"]`
*   **KeyVault:** `["vault"]`
*   **PostgreSQL:** `["postgresqlServer"]`
*   **ACR:** `["registry"]`
*   **SQL DB:** `["sqlServer"]`

---

### **Scenario A: Storage Account (Blob) Only**
*Connecting a Storage Account to a specific subnet.*

```hcl
module "storage_endpoints" {
  source              = "./modules/Private-Endpoints"
  resource_group_name = "rg-storage-prod"
  location            = "eastus"

  private_endpoints = {
    "pe-stg-logs" = {
      subnet_id                      = module.network.private_subnet_id
      private_connection_resource_id = azurerm_storage_account.logs.id
      subresource_names              = ["blob"]
      private_dns_zone_ids           = [module.dns.dns_zone_ids["privatelink.blob.core.windows.net"]]
    }
  }
}
```

### **Scenario B: Mixed Resources (App Stack)**
*Deploying endpoints for a full application stack (ACR, KeyVault, SQL) in one go.*

```hcl
module "app_endpoints" {
  source              = "./modules/Private-Endpoints"
  resource_group_name = "rg-app-prod"
  location            = "eastus"

  private_endpoints = {
    
    # 1. Container Registry
    "pe-acr" = {
      subnet_id                      = var.subnet_app_id
      private_connection_resource_id = azurerm_container_registry.main.id
      subresource_names              = ["registry"]
      private_dns_zone_ids           = [module.dns.dns_zone_ids["privatelink.azurecr.io"]]
    },

    # 2. Key Vault
    "pe-kv" = {
      subnet_id                      = var.subnet_security_id
      private_connection_resource_id = azurerm_key_vault.main.id
      subresource_names              = ["vault"]
      private_dns_zone_ids           = [module.dns.dns_zone_ids["privatelink.vaultcore.azure.net"]]
    },

    # 3. PostgreSQL Database
    "pe-db" = {
      subnet_id                      = var.subnet_data_id
      private_connection_resource_id = azurerm_postgresql_server.main.id
      subresource_names              = ["postgresqlServer"]
      private_dns_zone_ids           = [module.dns.dns_zone_ids["privatelink.postgres.database.azure.com"]]
    }
  }
}
```

### **Scenario C: Private Endpoint without DNS Integration**
*Sometimes you handle DNS via custom Forwarders/Appliances and don't want Azure Private DNS Groups.*

```hcl
module "endpoints_no_dns" {
  source              = "./modules/Private-Endpoints"
  resource_group_name = "rg-networking"
  location            = "eastus"

  private_endpoints = {
    "pe-blob-custom" = {
      subnet_id                      = var.subnet_id
      private_connection_resource_id = azurerm_storage_account.main.id
      subresource_names              = ["blob"]
      private_dns_zone_ids           = [] # Empty list = No DNS integration
    }
  }
}
```