### MODULE-GUIDE.md

Here is the guide documentation. You can save this file inside the module folder.

# Azure PostgreSQL Flexible Server Module Guide

## Overview
This module creates a highly configurable PostgreSQL Flexible Server. It supports three distinct architectural patterns:
1.  **Public Access:** For Dev/Test (cheapest).
2.  **Private Endpoint:** Using Private Link (Modern Standard for Hub/Spoke).
3.  **VNet Integrated:** Using Subnet Delegation (Classic Secure Method).

---

## 🛠 Usage Examples

### Example 1: High Security Production (CMK + HA + Private Endpoint)
*Most likely your requirement. Uses `public_network_access = false`, encrypts with Key Vault, enables HA, and you attach a Private Endpoint in your root module.*

```hcl
# 1. Identity for Postgres
module "psql_uai" {
  source     = "../../modules/User-Assigned-Identity"
  identities = { "id-psql-prod" = { name="id-psql-prod", ... } }
}

# 2. Key for CMK
resource "azurerm_key_vault_key" "psql" {
  # ... Ensure Identity has Wrap/Unwrap permissions ...
}

# 3. Create Server
module "postgres" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-erp-prod"
  resource_group_name = var.rg_name
  location            = var.location
  
  # Capacity
  sku_name   = "GP_Standard_D4s_v3"
  storage_mb = 131072 # 128GB

  # Admin
  admin_username = "psqladmin"
  admin_password = var.db_password # Get from KeyVault

  # Networking (Private Link Mode)
  public_network_access_enabled = false
  delegated_subnet_id           = null # We use PE, not Delegation

  # High Availability (Zone Redundant)
  ha_mode      = "ZoneRedundant"
  zone         = "1"
  standby_zone = "2"

  # CMK Security
  cmk_enabled                   = true
  cmk_key_vault_key_id          = azurerm_key_vault_key.psql.id
  cmk_user_assigned_identity_id = module.psql_uai.identities["id-psql-prod"].id
  identity_id                   = module.psql_uai.identities["id-psql-prod"].id

  tags = { Environment = "Production" }
}

# 4. Attach Private Endpoint (Using your existing module)
module "pe_postgres" {
  source = "../../modules/Private-Endpoints"
  # ... config ...
  private_endpoints = {
    "pe-psql" = {
      subnet_id                      = var.pe_subnet_id
      private_connection_resource_id = module.postgres.id
      subresource_names              = ["postgresqlServer"] # Use this literal string
      private_dns_zone_ids           = [module.dns.dns_zone_ids["privatelink.postgres.database.azure.com"]]
    }
  }
}
```

---

### Example 2: Simple Development (Public Access)
*Low cost, B-series SKU, Public IP allowed.*

```hcl
module "postgres_dev" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-erp-dev"
  resource_group_name = var.rg_name
  location            = var.location
  
  sku_name            = "B_Standard_B1ms" # Cheapest
  storage_mb          = 32768
  
  admin_username = "devadmin"
  admin_password = "StrongPassword123!"

  # Networking
  public_network_access_enabled = true # Allowed
  
  # Parameters (Optional)
  server_parameters = {
    "require_secure_transport" = "OFF" # Example only
  }
}
```

---

### Example 3: VNet Injection (Delegated Subnet)
*The traditional "Private" way. Requires a subnet explicitly delegated to `Microsoft.DBforPostgreSQL/flexibleServers`.*

```hcl
module "postgres_delegated" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  # ... base config ...

  # Networking (Delegation Mode)
  public_network_access_enabled = false
  delegated_subnet_id           = module.vnet.subnet_ids["vnet-main"]["db-subnet"]
  private_dns_zone_id           = module.private_dns.dns_zone_ids["privatelink.postgres.database.azure.com"]
}
```

---

### Important Notes on Networking
1.  **Firewall:** This module **does not** create internal firewall rules. If using Private Endpoint, access is controlled via Network Security Groups (NSGs) on the PE Subnet.
2.  **DNS:** For Private Endpoint connectivity, you **must** use the DNS Zone `privatelink.postgres.database.azure.com`.
3.  **Roles:** For CMK, ensure the Identity has `Key Vault Crypto Service Encryption User` permission.