# Azure PostgreSQL Flexible Server Module Guide

## 📋 Overview
**Directory:** `modules/PostgreSQL-Flexible-Server`

This module provision an **Azure Database for PostgreSQL - Flexible Server**. It is designed to support three major architectural patterns:
1.  **Private Link (Recommended):** Server has no public access; connectivity is via a Private Endpoint in your VNet.
2.  **VNet Injection:** The server is injected directly into a Delegated Subnet.
3.  **Public Access:** For development/testing (firewall protected).

It also supports Enterprise features like **High Availability (HA)**, **Customer Managed Keys (CMK)**, and **Entra ID (AAD) Authentication**.

---

## 🛠 Prerequisites
Before deploying a secure instance, ensure you have:
*   **Resource Group**: Created beforehand.
*   **Key Vault & Key**: If using CMK.
*   **User Assigned Identity (UAI)**: If using CMK (The Identity must have `Key Vault Crypto Service Encryption User` permissions).
*   **Private DNS Zone**: `privatelink.postgres.database.azure.com` (If using Private Link/VNet Injection).

---

## 🚀 Usage Examples

### Scenario 1: Enterprise Production (Private Endpoint + CMK + HA)
**Best for:** Production workloads requiring maximum security and availability.
*   **Network:** No Public Access. Connection via Private Endpoint.
*   **Security:** Disk encrypted with your Key (CMK).
*   **Availability:** Zone Redundant HA (Standby in Zone 2).

```hcl
# 1. Define the User Identity for CMK (Must have KV Permissions)
module "psql_identity" {
  source     = "../../modules/User-Assigned-Identity"
  identities = { "id-psql-prod" = { name="id-psql-prod", ... } }
}

# 2. Deploy PostgreSQL Server
module "postgres_prod" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-erp-prod-01"
  resource_group_name = var.rg_name
  location            = var.location

  # Compute & Storage (Production Grade)
  sku_name   = "GP_Standard_D2s_v5" # General Purpose, 2 vCore
  storage_mb = 131072               # 128 GB
  
  # Credentials
  admin_username = "psqladmin"
  admin_password = var.db_password_secure

  # Networking: DISABLE Public Access. 
  # We are NOT using Vnet Injection here, so delegated_subnet_id is null.
  public_network_access_enabled = false
  delegated_subnet_id           = null 

  # High Availability
  ha_mode      = "ZoneRedundant"
  zone         = "1"
  standby_zone = "2"

  # Encryption (CMK)
  cmk_enabled          = true
  cmk_key_vault_key_id = azurerm_key_vault_key.my_key.id
  # Identity used by Postgres to unwrap the Key
  cmk_identity_id      = module.psql_identity.identities["id-psql-prod"].id

  tags = { Environment = "Production" }
}

# 3. Create Private Endpoint (Connects VNet -> Postgres)
module "pe_postgres" {
  source              = "../../modules/Private-Endpoints"
  resource_group_name = var.rg_name
  location            = var.location

  private_endpoints = {
    "pe-psql-prod" = {
      subnet_id                      = module.vnet.subnet_ids["vnet-main"]["private-endpoints"]
      private_connection_resource_id = module.postgres_prod.id
      subresource_names              = ["postgresqlServer"] # Crucial: Must be this string
      private_dns_zone_ids           = [module.private_dns.dns_zone_ids["privatelink.postgres.database.azure.com"]]
    }
  }
}
```

---

### Scenario 2: VNet Injection (Delegated Subnet)
**Best for:** Legacy "Private" architectures or strict compliance requirements mandating subnet injection.
*   **Requirement:** You must have a Subnet dedicated/delegated to `Microsoft.DBforPostgreSQL/flexibleServers`.
*   **Note:** You cannot use Private Endpoint and VNet Injection simultaneously.

```hcl
module "postgres_vnet_injected" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-injected-01"
  resource_group_name = var.rg_name
  location            = var.location

  # Compute
  sku_name   = "GP_Standard_D2s_v3"
  
  # Networking Configuration for Injection
  public_network_access_enabled = false
  
  # 1. The ID of the subnet specifically delegated to Postgres
  delegated_subnet_id = module.vnet.subnet_ids["vnet-main"]["delegated-db-subnet"]
  
  # 2. The ID of the Private DNS Zone (Must be linked to the VNet)
  private_dns_zone_id = module.private_dns.dns_zone_ids["privatelink.postgres.database.azure.com"]

  tags = { Type = "VNet-Integrated" }
}
```

---

### Scenario 3: Development / Sandbox (Public Access)
**Best for:** Quick prototyping, testing connection from local machines (requires Firewall rules, which are managed separately or manually).
*   **Cost:** Uses "Burstable" (B-Series) SKU.
*   **Security:** CMK Disabled, HA Disabled.

```hcl
module "postgres_dev" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-erp-dev"
  resource_group_name = var.rg_name
  location            = var.location

  # Cheapest Cost Configuration
  sku_name            = "B_Standard_B1ms" # Burstable
  storage_mb          = 32768             # 32 GB
  backup_retention_days = 7
  ha_mode             = null              # Disable HA

  # Credentials
  admin_username = "devadmin"
  admin_password = "SafePassword123!"

  # Network
  public_network_access_enabled = true
  delegated_subnet_id           = null

  # Parameters (Server Configuration)
  server_parameters = {
    "require_secure_transport" = "OFF" # Optional: Allow non-SSL for simple dev tests
    "log_connections"          = "ON"
  }

  tags = { Environment = "Dev" }
}
```

---

## 🔍 Key Variables Reference

| Variable | Type | Description |
| :--- | :--- | :--- |
| `sku_name` | string | VM Size. Use `GP_Standard_D2s_v5` for Prod, `B_Standard_B1ms` for Dev. |
| `storage_mb` | number | Disk size. `32768` (32GB), `65536` (64GB), `131072` (128GB). |
| `ha_mode` | string | `ZoneRedundant` (Best for Prod), `SameZone`, or `null` (Disabled). |
| `cmk_enabled` | bool | `true` enables encryption. Requires `cmk_key_vault_key_id` AND `cmk_identity_id`. |
| `public_network_access_enabled` | bool | Set `false` if using Private Endpoint. |
| `server_parameters` | map | Key/Value pairs for `postgresql.conf` settings (e.g. logging, timeouts). |

## ⚠️ CMK Permissions Check
If `cmk_enabled = true`, the creation will fail unless the User Assigned Identity (`cmk_identity_id`) **already** has these permissions on the Key Vault:
*   `Get`, `WrapKey`, `UnwrapKey`
*   In RBAC: Assign the role **"Key Vault Crypto Service Encryption User"**.