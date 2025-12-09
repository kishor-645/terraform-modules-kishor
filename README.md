# Terraform Modules Library - Complete Reference

**Last Updated:** January 2024  
**Terraform Version:** >= 1.0  
**Azure Provider:** >= 3.0

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Module Summary](#module-summary)
4. [Core Patterns](#core-patterns)
5. [Usage Examples](#usage-examples)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Creating Multi-Resource Modules

All modules support creating multiple resources in a single module call. Use map-based inputs:

```hcl
# Example: Create multiple storage accounts
module "storage" {
  source = "./modules/Storage-Accounts"
  
  registries = {
    "storage-prod" = {
      resource_group_name      = "rg-prod"
      location                 = "eastus"
      account_tier             = "Standard"
      account_replication_type = "GRS"
      cmk_enabled              = true
      cmk_key_vault_key_id     = "/subscriptions/.../keys/storage-key"
      tags                     = { env = "prod" }
    }
    "storage-staging" = {
      resource_group_name      = "rg-staging"
      location                 = "eastus"
      account_tier             = "Standard"
      account_replication_type = "LRS"
      cmk_enabled              = false
      tags                     = { env = "staging" }
    }
  }
  
  common_tags = {
    project    = "intech"
    managed_by = "terraform"
  }
}
```

See `environment/example.tfvars` for complete, real-world scenarios.

---

## Architecture Overview

### Deployment Structure

```
environment/
├── prod/
│   ├── main.tf          # Root module combining all infrastructure modules
│   └── provider.tf      # Azure provider configuration
└── example.tfvars       # Example variables for all modules

modules/
├── RG/                  # Foundation: Resource Groups
├── Vnet/                # Networking: Virtual Networks
├── Storage-Accounts/    # Data: Azure Storage
├── Key-Vaults/          # Security: Key Vaults with RBAC
├── PostgreSQL-Flexible-Server/  # Database: PostgreSQL
├── Azure-Container-Registries/  # Container: ACR with CMK
├── AKS-Private-Cluster/         # Compute: AKS with disk encryption
├── Azure-Firewall/              # Security: Firewall & policies
├── App-Gateway/                 # Load Balancing: App Gateway
├── User-Assigned-Identity/      # IAM: Managed Identities
├── Role-Assignment/             # IAM: RBAC bindings
├── Diagnostic-Settings/         # Monitoring: Logs to Log Analytics
├── Log-Analytics-Workspace/     # Observability: LAW
└── [Other modules...]           # Linux/Windows VMs, Private Endpoints, etc.
```

### Module Interconnections

```
RG (Foundation)
  ├─→ Vnet (Networking)
  │    ├─→ AKS (Compute)
  │    ├─→ App-Gateway (Load Balancing)
  │    └─→ Azure-Firewall (Security)
  │
  ├─→ Storage-Accounts (Data)
  │    └─→ Diagnostic-Settings (Observability)
  │
  ├─→ Key-Vaults (Security)
  │    └─→ Role-Assignment (Access Control)
  │
  ├─→ PostgreSQL-Flexible-Server (Database)
  │    └─→ Private-Endpoints (Private Connectivity)
  │
  └─→ Azure-Container-Registries (Container Registry)
       └─→ Private-Endpoints (Private Connectivity)
```

---

## Module Summary

| Module | Purpose | Multi-Resource | CMK Support | Status |
|--------|---------|:---------------:|:-----------:|:------:|
| **RG** | Foundation resource groups | ✅ | ❌ | ✅ Fully Dynamic |
| **Vnet** | Virtual networks & subnets | ✅ | ❌ | ✅ Ready |
| **Storage-Accounts** | Blob, file, queue storage | ✅ | ✅ | ✅ Fully Dynamic |
| **Key-Vaults** | Secret & key management | ✅ | ❌ | ✅ Fully Dynamic |
| **PostgreSQL-Flexible-Server** | Managed PostgreSQL | ✅ | ✅ | ✅ Fully Dynamic |
| **Azure-Container-Registries** | Private image registry | ✅ | ✅ | ✅ Fully Dynamic |
| **AKS-Private-Cluster** | Kubernetes cluster | ❌ | ✅ (DES) | ✅ Ready |
| **Azure-Firewall** | Firewall & policies | ❌ | ❌ | ✅ Ready |
| **App-Gateway** | HTTP(S) load balancer | ❌ | ✅ | ✅ Ready |
| **User-Assigned-Identity** | Managed identities | ✅ | ❌ | ✅ New |
| **Role-Assignment** | RBAC bindings | ✅ | ❌ | ✅ New |
| **Diagnostic-Settings** | Log forwarding | ✅ | ❌ | ✅ Ready |
| **Log-Analytics-Workspace** | Observability backend | ✅ | ❌ | ✅ Ready |
| **Azure-Private-Endpoints** | Private connectivity | ✅ | ❌ | ✅ Ready |
| **Private-DNS-Zone** | Private DNS | ✅ | ❌ | ✅ Ready |
| **Linux-Virtual-Machines** | Linux compute | ✅ | ❌ | ✅ Ready |
| **Windows-Virtual-Machines** | Windows compute | ✅ | ❌ | ✅ Ready |
| **Vnet-peering** | VNet-to-VNet connectivity | ✅ | ❌ | ✅ Ready |

---

## Core Patterns

### Pattern 1: Multi-Resource Map

**Used By:** RG, Storage, Key Vault, PostgreSQL, ACR, UAI, etc.

```hcl
variable "resources" {
  type = map(object({
    resource_group_name = string
    location            = string
    # ... other per-resource config ...
  }))
  default = {}
}

resource "azurerm_resource_type" "this" {
  for_each = var.resources
  
  name                = each.key
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  # ...
}

output "resource_ids" {
  value = { for name, resource in azurerm_resource_type.this : name => resource.id }
}
```

### Pattern 2: Dynamic Block (CMK Support)

**Used By:** Storage, PostgreSQL, ACR, AKS, etc.

```hcl
variable "cmk_enabled" {
  type = bool
  default = false
}

variable "cmk_key_vault_key_id" {
  type = string
  default = ""
}

resource "azurerm_resource_type" "this" {
  # ... base config ...
  
  dynamic "encryption" {
    for_each = var.cmk_enabled && length(trim(var.cmk_key_vault_key_id)) > 0 ? [1] : []
    content {
      key_vault_key_id = var.cmk_key_vault_key_id
    }
  }
}
```

### Pattern 3: Backward Compatibility (Deprecated Inputs)

**Used By:** RG, Storage, Key Vault, PostgreSQL, ACR

Old single-resource modules maintain compatibility via `count`:

```hcl
# Multi-resource (new)
resource "azurerm_resource_type" "this" {
  for_each = var.resources
  # ...
}

# Legacy single-resource (count-based, backward compatible)
resource "azurerm_resource_type" "legacy" {
  count = (length(var.resources) == 0 && var.resource_name != "") ? 1 : 0
  # ...
}

output "resource_id" {
  # Returns legacy output or first from map
  value = try(azurerm_resource_type.legacy[0].id, values(azurerm_resource_type.this)[0].id, null)
}
```

---

## Usage Examples

### Example 1: Complete Foundation (RG + Vnet + Storage)

```hcl
# main.tf
module "resource_groups" {
  source = "./modules/RG"
  
  resource_groups = {
    "rg-prod-eastus" = {
      location = "eastus"
    }
  }
  
  common_tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}

module "storage" {
  source = "./modules/Storage-Accounts"
  
  storage_accounts = {
    "stgprodapp001" = {
      resource_group_name      = module.resource_groups.resource_group_names["rg-prod-eastus"]
      location                 = "eastus"
      account_tier             = "Standard"
      account_replication_type = "GRS"
      cmk_enabled              = true
      cmk_key_vault_key_id     = azurerm_key_vault_key.storage_key.id
    }
  }
  
  depends_on = [module.resource_groups]
}
```

### Example 2: PostgreSQL with CMK & High Availability

```hcl
module "postgresql" {
  source = "./modules/PostgreSQL-Flexible-Server"
  
  postgresql_servers = {
    "prod-db-primary" = {
      resource_group_name    = "rg-prod-eastus"
      location               = "eastus"
      sku_name               = "Standard_B4ms"
      storage_mb             = 131072
      backup_retention_days  = 35
      geo_redundant_backup   = true
      
      admin_username = var.db_admin_user
      admin_password = var.db_admin_password  # Use var.sensitive_var
      
      cmk_enabled          = true
      cmk_key_vault_key_id = module.key_vaults.key_vault_key_ids["prod-db-cmk"]
      
      tags = { tier = "production" }
    }
  }
  
  depends_on = [module.key_vaults, module.resource_groups]
}
```

### Example 3: ACR with Managed Identity & CMK

```hcl
module "identities" {
  source = "./modules/User-Assigned-Identity"
  
  user_assigned_identities = {
    "mid-acr-prod" = {
      resource_group_name = "rg-prod-eastus"
      location            = "eastus"
      tags                = { purpose = "acr-cmk" }
    }
  }
}

module "registries" {
  source = "./modules/Azure-Container-Registries"
  
  registries = {
    "acrprodus" = {
      resource_group_name           = "rg-prod-eastus"
      location                      = "eastus"
      sku                           = "Premium"
      admin_enabled                 = false
      public_network_access_enabled = false
      
      cmk_enabled              = true
      cmk_key_vault_key_id     = azurerm_key_vault_key.acr_key.id
      cmk_identity_id          = module.identities.identity_ids["mid-acr-prod"]
      
      tags = { tier = "production" }
    }
  }
}
```

---

## Best Practices

### 1. State & Terraform Backend
- **Use Remote Backend:** Azure Storage account or Terraform Cloud
- **Lock State:** Enable blob storage versioning & soft delete
- **Access Control:** RBAC for state file access
- **Example:**
  ```hcl
  terraform {
    backend "azurerm" {
      resource_group_name  = "rg-terraform"
      storage_account_name = "tfstate001"
      container_name       = "tfstate"
      key                  = "prod.tfstate"
    }
  }
  ```

### 2. Security & Encryption
- **CMK for Sensitive Data:** Always enable CMK for Storage, PostgreSQL, ACR in production
- **Key Vault Access:** Use RBAC authorization (not legacy access policies)
- **Identities:** Create separate managed identities per resource type for least privilege
- **Network:** Use Private Endpoints for all data services
- **Example:**
  ```hcl
  cmk_enabled              = true
  cmk_key_vault_key_id     = azurerm_key_vault_key.this.id
  cmk_identity_id          = azurerm_user_assigned_identity.this.id
  ```

### 3. Networking & Isolation
- **Subnets:** Separate subnets per workload (AKS, Database, App Gateway)
- **NSGs:** Define Network Security Groups per subnet
- **Private Endpoints:** Enable for Storage, Key Vault, Database, ACR
- **Firewall Rules:** Restrict access by resource type and tier

### 4. Observability & Diagnostics
- **Log Analytics:** Central logging workspace for all resources
- **Diagnostic Settings:** Enable for all compute and data resources
- **Alerts:** Define metric and log-based alerts for production workloads
- **Example:**
  ```hcl
  module "diagnostics" {
    for_each               = module.storage.acr_ids
    source                 = "./modules/Diagnostic-Settings"
    target_resource_id     = each.value
    log_analytics_workspace_id = module.law.workspace_id
  }
  ```

### 5. Cost Optimization
- **Right-Sizing:** Use Standard tier for non-production, Premium for production
- **Redundancy:** LRS for dev/test, GRS for production
- **Scheduled Scaling:** Use auto-scaling for AKS, App Service
- **Reserved Instances:** For predictable long-running workloads

### 6. High Availability & Disaster Recovery
- **Multi-Region:** Deploy primary and replica in different regions
- **Geo-Redundant Backups:** Enable for databases (PostgreSQL)
- **Traffic Management:** Use Traffic Manager or Front Door for failover
- **RTO/RPO:** Define recovery time and point objectives

### 7. Tagging & Organization
- **Common Tags:** Apply organization-wide tags (environment, team, cost-center)
- **Per-Resource Tags:** Add workload-specific tags
- **Consistency:** Use terraform.tfvars for centralized tag definitions
- **Example:**
  ```hcl
  common_tags = {
    environment = "production"
    project     = "intech-platform"
    team        = "platform"
    cost_center = "1001"
    managed_by  = "terraform"
  }
  ```

---

## Troubleshooting

### Issue: CMK Key Vault Key Not Found
**Cause:** Key doesn't exist or identity lacks permissions  
**Solution:**
1. Verify key exists: `az keyvault key list --vault-name <vault-name>`
2. Grant identity access: `az role assignment create --assignee <identity-id> --role "Key Vault Crypto Service Encryption User"`

### Issue: Terraform Lock Timeout
**Cause:** State file is locked (another run in progress)  
**Solution:**
1. Check other runs: `terraform show`
2. Force unlock only if safe: `terraform force-unlock <LOCK_ID>`
3. Use `backend "azurerm" { skip_provider_registration = true }` if provider issues

### Issue: Insufficient Permissions
**Cause:** Service principal lacks role assignment  
**Solution:**
1. Assign role: `az role assignment create --assignee <sp-id> --role "Contributor"`
2. For specific scopes: `--scope /subscriptions/<sub-id>/resourceGroups/<rg>`

### Issue: Private Endpoint Connection Fails
**Cause:** DNS resolution or network rules blocking access  
**Solution:**
1. Verify private endpoint created: `az network private-endpoint show -n <pep-name>`
2. Check NSG rules: Allow traffic on required ports
3. Verify private DNS zone: Link VNET to private DNS zone

### Issue: PostgreSQL CMK Not Applying
**Cause:** Key vault key permissions or encryption block syntax  
**Solution:**
1. Verify identity has "Key Vault Crypto Service Encryption User" role
2. Check key_vault_key_id format: `/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/.../keys/.../versions/...`
3. Ensure `cmk_enabled = true` and key ID is not empty

---

## Variable Files

Use `environment/example.tfvars` for multi-environment deployments:

```bash
# Production
terraform apply -var-file="environment/prod.tfvars"

# Staging  
terraform apply -var-file="environment/staging.tfvars"

# Development
terraform apply -var-file="environment/dev.tfvars"
```

---

## Documentation Structure

- **This File** (`MODULES-COMPLETE-REFERENCE.md`): Central reference with all patterns, examples, and best practices
- **Per-Module Guides** (archived/reference only): Detailed guide for complex modules (RG, Storage, Key Vault, ACR, PostgreSQL)
- **Example Variables** (`environment/example.tfvars`): Real-world multi-environment scenarios
- **Module README** (per module): Quick reference for each module's specific inputs/outputs

---

## Quick Links

- **Azure Terraform Provider Docs:** https://registry.terraform.io/providers/hashicorp/azurerm
- **Azure Well-Architected Framework:** https://learn.microsoft.com/azure/well-architected/
- **Terraform Best Practices:** https://www.terraform.io/docs/language/index.html
- **Azure Security Baseline:** https://learn.microsoft.com/security/benchmark/azure/

---

**Last Updated:** January 2024 | **Version:** 2.0
