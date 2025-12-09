# Storage Accounts Module Guide

## Overview

The **Storage Accounts** module is a flexible Terraform module for creating **one or multiple Azure Storage Accounts** with advanced features including Customer Managed Keys (CMK), dynamic tagging, and per-account configuration. This module is fully dynamic and allows independent configuration of each storage account.

### Key Features
- ✅ Create **multiple storage accounts** in a single call
- ✅ **Per-account configuration** — different tiers, replication, and CMK settings
- ✅ **Customer Managed Key (CMK)** support for encryption
- ✅ **Dynamic tagging** — common tags + per-account tags
- ✅ **Infrastructure encryption** — optional double encryption layer
- ✅ **Backward compatible** — supports legacy single-storage inputs

---

## Directory Structure

```
modules/
└── Storage-Accounts/
    ├── storage_accounts.tf
    ├── cmk.tf                # CMK guidance
    ├── variables.tf
    ├── output.tf
    └── STORAGE-MODULE-GUIDE.md
```

---

## Module Variables

### Primary Inputs

| Variable | Type | Default | Description |
|---|---|---|---|
| `resource_group_name` | `string` | *(required)* | Target resource group name |
| `location` | `string` | *(required)* | Azure region for all storage accounts |
| `storage_accounts` | `map(object)` | `{}` | Map of storage accounts to create |
| `common_tags` | `map(string)` | `{}` | Tags applied to all storage accounts |

#### `storage_accounts` Object Structure

Each key in the map becomes the storage account name. Object contains:

```hcl
storage_accounts = {
  "mystorageacct" = {
    account_tier                      = "Standard"
    account_replication_type          = "LRS"
    public_network_access_enabled     = false
    infrastructure_encryption_enabled = false
    cmk_enabled                       = false
    cmk_key_vault_key_id              = ""
    cmk_user_assigned_identity_id     = ""
    tags = {
      purpose = "data-lake"
    }
  }
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `account_tier` | `string` | `"Standard"` | Storage tier: `Standard` or `Premium` |
| `account_replication_type` | `string` | `"LRS"` | Replication: `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS` |
| `public_network_access_enabled` | `bool` | `false` | Allow public access |
| `infrastructure_encryption_enabled` | `bool` | `false` | Enable double encryption (infrastructure + customer) |
| `cmk_enabled` | `bool` | `false` | Enable Customer Managed Key encryption |
| `cmk_key_vault_key_id` | `string` | `""` | Full resource ID of Key Vault Key (if CMK enabled) |
| `cmk_user_assigned_identity_id` | `string` | `""` | UAI ID with unwrap permissions on CMK key |
| `tags` | `map(string)` | `{}` | Account-specific tags |

---

## Module Outputs

| Output | Type | Description |
|---|---|---|
| `storage_accounts` | `map(object)` | Map of all created accounts with `id`, `name`, `primary_blob_endpoint` |

### Output Structure

```hcl
storage_accounts = {
  "mystorageacct" = {
    id                    = "/subscriptions/.../storageAccounts/mystorageacct"
    name                  = "mystorageacct"
    primary_blob_endpoint = "https://mystorageacct.blob.core.windows.net/"
  }
}
```

---

## Usage Examples

### Example 1: Single Storage Account with LRS

```hcl
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "appstorageacct" = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      public_network_access_enabled = false
    }
  }

  common_tags = {
    environment = "production"
    project     = "my-app"
  }
}

# Access outputs
output "storage_id" {
  value = module.storage.storage_accounts["appstorageacct"].id
}
```

---

### Example 2: Multiple Storage Accounts with Different Tiers

```hcl
module "storage_multi" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "appdata" = {
      account_tier             = "Standard"
      account_replication_type = "GRS"
      tags = {
        purpose = "application-data"
      }
    }
    "backups" = {
      account_tier             = "Standard"
      account_replication_type = "RAGRS"
      tags = {
        purpose = "backups"
      }
    }
    "cache" = {
      account_tier             = "Premium"
      account_replication_type = "LRS"
      tags = {
        purpose = "high-performance-cache"
      }
    }
  }

  common_tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

---

### Example 3: Storage with CMK Encryption

```hcl
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "kv-storage-cmk" = {
      sku_name = "standard"
    }
  }
}

module "uai" {
  source = "./modules/User-Assigned-Identity"

  identities = {
    storage_cmk_identity = {
      name           = "storage-cmk-uai"
      resource_group = "rg-prod"
      location       = "eastus"
    }
  }
}

module "storage_cmk" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "securedata" = {
      account_tier                      = "Standard"
      account_replication_type          = "GRS"
      infrastructure_encryption_enabled = true
      cmk_enabled                       = true
      cmk_key_vault_key_id              = "/subscriptions/.../keys/storage-key/xyz"
      cmk_user_assigned_identity_id     = module.uai.identities["storage_cmk_identity"].id
      tags = {
        encryption = "cmk"
      }
    }
  }

  common_tags = {
    environment = "production"
    security    = "high"
  }
}
```

---

### Example 4: Storage Across Multiple Regions

```hcl
module "storage_regional" {
  for_each = toset(["eastus", "westus2"])

  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod-${each.value}"
  location            = each.value

  storage_accounts = {
    "storage${each.value}" = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      tags = {
        region = each.value
      }
    }
  }

  common_tags = {
    environment = "production"
    replicated  = "yes"
  }
}

# Access regional storage
output "east_storage_id" {
  value = module.storage_regional["eastus"].storage_accounts["storageeastus"].id
}

output "west_storage_id" {
  value = module.storage_regional["westus2"].storage_accounts["storagewestus2"].id
}
```

---

## Dynamicity & Scalability

| Aspect | Support |
|---|---|
| **Create multiple accounts** | ✅ Yes — via `storage_accounts` map |
| **Per-account tiers** | ✅ Yes — each account can have different tier/replication |
| **CMK encryption** | ✅ Yes — per-account toggle with Key Vault integration |
| **Infrastructure encryption** | ✅ Yes — optional double encryption layer |
| **Per-account tags** | ✅ Yes — custom tags + common tags merge |
| **Backward compatibility** | ✅ Yes — legacy single-storage inputs supported |

---

## Integration with Other Modules

### With User-Assigned-Identity for CMK

```hcl
# Create UAI for storage encryption
module "storage_uai" {
  source = "./modules/User-Assigned-Identity"

  identities = {
    storage_identity = {
      name           = "storage-cmk-identity"
      resource_group = "rg-prod"
      location       = "eastus"
    }
  }
}

# Use UAI in storage module
module "secure_storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "secure-data" = {
      cmk_enabled                   = true
      cmk_key_vault_key_id          = azurerm_key_vault_key.storage_key.id
      cmk_user_assigned_identity_id = module.storage_uai.identities["storage_identity"].id
    }
  }
}
```

### With Private Endpoints

```hcl
# Create storage (private access disabled)
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "private-storage" = {
      public_network_access_enabled = false
    }
  }
}

# Create private endpoint
module "pe" {
  source = "./modules/Azure-Private-Endpoints"

  resource_group_name = "rg-prod"
  location            = "eastus"

  private_endpoints = {
    "storage-pe" = {
      resource_id       = module.storage.storage_accounts["private-storage"].id
      subresource_names = ["blob"]
      subnet_id         = azurerm_subnet.private.id
    }
  }
}
```

---

## Best Practices

1. **Use meaningful names** — Include purpose in name (e.g., `appdata`, `backups`, `cache`)
2. **Choose replication wisely:**
   - `LRS` = single region, low cost
   - `GRS`/`RAGRS` = geo-replication for high availability
   - `ZRS` = zone redundancy within region
3. **Enable CMK for sensitive data** — Especially for production workloads
4. **Disable public access** by default — Use Private Endpoints for secure access
5. **Apply consistent tags** — Use `common_tags` for all accounts
6. **Use infrastructure encryption** for double-encryption layer when handling highly sensitive data
7. **Monitor storage costs** — Premium tier is expensive; use only where needed

---

## Troubleshooting

### Issue: "Storage account name already exists"
**Solution:** Storage account names must be globally unique in Azure. Use prefixes/suffixes with timestamps or region codes.

### Issue: CMK encryption fails
**Solution:** Ensure:
- Key Vault key exists and is accessible
- UAI has `unwrapKey` and `get` permissions on the key
- Key Vault has soft delete enabled
- Key type is `RSA` or `EC`

### Issue: Cannot access storage account after creation
**Solution:** If `public_network_access_enabled = false`, use Private Endpoints or configure Key Vault/network rules.

---

## Storage Account Names — Important Notes

- Must be 3-24 characters, lowercase letters and numbers only
- Must be globally unique across all Azure subscriptions
- Cannot start with a number
- No hyphens or underscores

Example valid names:
- `appdata2024prod`
- `backupseastus01`
- `cacheprod`

---

## Limitations & Considerations

- **Global uniqueness:** Storage account names must be unique across entire Azure platform
- **Name constraints:** 3-24 chars, lowercase + numbers only
- **Replication trade-offs:** More replication = higher cost
- **CMK key rotation:** Must be managed separately via Key Vault policies
- **Access control:** Use RBAC roles or shared access signatures (SAS) for fine-grained permissions

---

## Summary

The Storage Accounts module provides a **flexible, secure, and scalable way** to create Azure Storage Accounts with enterprise-grade features. Use the `storage_accounts` map to create **multiple accounts** with **independent configurations**, **CMK encryption**, and **custom tags**. Perfect for multi-tier architectures, multi-region deployments, and compliance-heavy workloads.

