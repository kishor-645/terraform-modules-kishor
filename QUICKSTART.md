# Quick Reference: Module Library

---

## 🚀 Getting Started (5 Minutes)

### 1. Create Resource Groups
```hcl
module "rg" {
  source = "./modules/RG"
  resource_groups = {
    "rg-prod" = { location = "eastus" }
  }
}
```

### 2. Create Vnet + Subnets
```hcl
module "vnet" {
  source = "./modules/Vnet"
  vnets = {
    "vnet-prod" = {
      resource_group_name = "rg-prod"
      location = "eastus"
      address_space = ["10.0.0.0/16"]
      subnets = {
        "subnet-app" = { address_prefixes = ["10.0.1.0/24"] }
      }
    }
  }
}
```

### 3. Create Storage with Encryption
```hcl
module "storage" {
  source = "./modules/Storage-Accounts"
  storage_accounts = {
    "storageaccount" = {
      resource_group_name = "rg-prod"
      location = "eastus"
      account_tier = "Standard"
      account_replication_type = "GRS"
      cmk_enabled = true
      cmk_key_vault_key_id = azurerm_key_vault_key.this.id
    }
  }
}
```

---

## 📋 Module Patterns

| Pattern | Used By | Example |
|---------|---------|---------|
| **Multi-Resource Map** | RG, Storage, PostgreSQL, ACR | `for_each = var.resources` |
| **Dynamic Block** | Storage, PostgreSQL, ACR, AKS | `dynamic "encryption" { ... }` |
| **Backward Compat** | RG, Storage, PostgreSQL, ACR | Legacy `count` resource for old inputs |
| **User Identity** | ACR, Storage, AKS | Managed identity + role assignment |

---

## 🔐 Encryption (CMK) Quick Start

```hcl
# 1. Create Key Vault
module "kv" {
  source = "./modules/Key-Vaults"
  key_vaults = {
    "kv-prod" = { ... }
  }
}

# 2. Create Key in vault
resource "azurerm_key_vault_key" "storage" {
  name         = "storage-key"
  key_vault_id = module.kv.key_vault_ids["kv-prod"]
  key_type     = "RSA"
  key_size     = 2048
  key_ops      = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# 3. Create Identity
module "identity" {
  source = "./modules/User-Assigned-Identity"
  user_assigned_identities = {
    "mid-storage" = { resource_group_name = "rg-prod", location = "eastus" }
  }
}

# 4. Assign Key Vault Crypto role
module "rbac" {
  source = "./modules/Role-Assignment"
  role_assignments = {
    "storage-kv-access" = {
      scope              = module.kv.key_vault_ids["kv-prod"]
      role_definition_id = "/subscriptions/.../roleDefinitions/33fa6697-ed7f-4979-8f5c-ded4b415ae50" # Key Vault Crypto Service Encryption User
      principal_id       = module.identity.identity_principal_ids["mid-storage"]
    }
  }
}

# 5. Create Resource with CMK
module "storage" {
  source = "./modules/Storage-Accounts"
  storage_accounts = {
    "storageaccount" = {
      # ... base config ...
      cmk_enabled              = true
      cmk_key_vault_key_id     = azurerm_key_vault_key.storage.id
      cmk_identity_id          = module.identity.identity_ids["mid-storage"]
    }
  }
}
```

---

## 🏗️ Common Scenarios

### Scenario 1: Multi-Region HA Deployment

```hcl
# Variables
regions = ["eastus", "westus"]

# Create RGs in both regions
resource_groups = {
  for region in var.regions : "rg-prod-${region}" => {
    location = region
  }
}

# Create PostgreSQL primary + replica
postgresql_servers = {
  "prod-primary" = {
    location = "eastus"
    geo_redundant_backup = true
  }
  "prod-replica" = {
    location = "westus"
    geo_redundant_backup = false  # Replicas don't need additional backup
  }
}
```

### Scenario 2: Multiple Storage Tiers

```hcl
storage_accounts = {
  "hot-storage" = {
    access_tier = "Hot"
    account_replication_type = "GRS"  # High availability
  }
  "cool-storage" = {
    access_tier = "Cool"
    account_replication_type = "LRS"  # Cost-optimized
  }
  "archive-storage" = {
    access_tier = "Archive"
    account_replication_type = "LRS"
  }
}
```

### Scenario 3: Dev + Prod ACRs

```hcl
registries = {
  "acr-prod-us" = {
    sku = "Premium"
    admin_enabled = false
    public_network_access_enabled = false
    cmk_enabled = true
    tags = { env = "prod" }
  }
  "acr-dev-us" = {
    sku = "Basic"
    admin_enabled = true
    public_network_access_enabled = true  # Only for dev
    cmk_enabled = false
    tags = { env = "dev" }
  }
}
```

---

## 🔍 Output References

After module execution, reference outputs:

```hcl
# Resource Groups
module.rg.resource_group_ids["rg-prod"]
module.rg.resource_group_names["rg-prod"]

# Storage
module.storage.acr_ids["storageaccount"]
module.storage.storage_account_names["storageaccount"]

# PostgreSQL
module.postgresql.postgresql_server_ids["prod-primary"]
module.postgresql.postgresql_server_fqdns["prod-primary"]

# ACR
module.registries.acr_ids["acr-prod-us"]
module.registries.acr_login_servers["acr-prod-us"]

# Identity
module.identity.identity_ids["mid-storage"]
module.identity.identity_principal_ids["mid-storage"]
```

---

## 🛠️ Troubleshooting Commands

```bash
# Validate modules
terraform validate

# Check resource dependency graph
terraform graph

# Show resource details
terraform show -json | jq '.values.root_module.resources'

# Format code
terraform fmt -recursive ./modules

# Test ACR login
az acr login --name acrprodus

# Verify PostgreSQL connectivity
psql -h prod-primary.postgres.database.azure.com -U pgadmin@prod-primary -d postgres

# Check Key Vault key permissions
az keyvault key show --vault-name kv-prod --name storage-key

# List role assignments
az role assignment list --scope /subscriptions/.../resourceGroups/rg-prod --output table
```

---

## 📖 Documentation Map

| Need | Go To |
|------|-------|
| Overview & patterns | `README.md` |
| Real-world config | `environment/example.tfvars` |
| Module inventory | `ALL_MODULES_OVERVIEW.md` |
| Implementation details | `MODULES-COMPLETE-REFERENCE.md` |
| Roadmap | `MODULES_UPDATE_SUGGESTIONS.md` |
| This quick ref | `QUICKSTART.md` (you are here) |

---

## 🎯 Key Takeaways

✅ **Always use map-based inputs** for flexibility  
✅ **Enable CMK in production** for sensitive data  
✅ **Create managed identities** for least-privilege access  
✅ **Use common_tags** for consistent resource labeling  
✅ **Enable geo-redundancy** for HA services  
✅ **Private endpoints** for data services (Storage, PostgreSQL, ACR)  
✅ **Diagnostic settings** to log analytics workspace  

---

**Quick Ref Version:** 1.0 | **Last Updated:** January 2024
