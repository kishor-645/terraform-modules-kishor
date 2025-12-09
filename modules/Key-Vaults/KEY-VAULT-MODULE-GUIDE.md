This module creates one or more Key Vaults using the `key_vaults` map input.

Authorization modes supported:

 - `access_policy` (default): access policies are applied to each vault via dynamic `access_policy` blocks.
 - `rbac`: set `default_auth_type = "rbac"` or per-vault `auth_type = "rbac"` to enable Azure RBAC for the vault.

When using RBAC, assign roles (e.g. `Key Vault Crypto Service Encryption User`) using your role-assignment module.
Example - create a single Premium (HSM) vault using RBAC and a CMK key:

```hcl
module "kv_premium_cmk" {
  source = "../../modules/Key-Vaults"

  resource_group_name = "rg-test-tf"
  location            = "uksouth"

  # Create a single vault: provide one map entry. Per-vault `location` and `resource_group_name`
  # are optional — the module-level values are used unless overridden.
  default_auth_type = "rbac"
  key_vaults = {
    "tf-cmk-vault-test" = {
      sku_name                      = "premium"  # Premium enables HSM
      auth_type                     = "rbac"
      public_network_access_enabled = false
      soft_delete_retention_days    = 7
      purge_protection_enabled      = true
    }
  }

  common_tags = {
    environment = "tf-test"
    compliance  = "pci-dss"
  }
}
```
# Key Vaults Module Guide

## Overview

The **Key Vaults** module is a flexible Terraform module for creating **one or multiple Azure Key Vaults** with dynamic configuration, purge protection, and access policy support. This module is fully dynamic and allows independent configuration of each vault, making it ideal for managing cryptographic keys, secrets, and certificates across your infrastructure.

### Key Features
- ✅ Create **multiple Key Vaults** in a single call
- ✅ **Per-vault configuration** — different SKUs, network access, retention policies
- ✅ **Purge protection** — prevent accidental deletions of sensitive vaults
- ✅ **Soft delete support** — configurable retention days (90-default)
- ✅ **Dynamic tagging** — common tags + per-vault tags
- ✅ **Access policy management** — attach policies for identities and service principals
- ✅ **Backward compatible** — legacy single-vault inputs still supported

### Authorization Modes (RBAC vs Access Policy)

- **Two authorization models supported:** `access_policy` (classic model) and `rbac` (Azure RBAC model).
- **Default:** `access_policy` for backward compatibility. You can change this globally with the `default_auth_type` variable or per-vault using the `auth_type` field in the `key_vaults` map.
- **Behaviour:**
  - When `auth_type = "access_policy"`, the module will add `access_policy` blocks to the Key Vault resource (legacy model).
  - When `auth_type = "rbac"`, the module sets the Key Vault to use Azure RBAC for authorization (no `access_policy` blocks are configured).
  - The module validates and applies access policies only when the effective auth type is `access_policy`.

This gives you the flexibility to adopt RBAC for new vaults while keeping legacy vaults using access policies.

---

## Directory Structure

```
modules/
└── Key-Vaults/
  ├── key_vault.tf
  ├── variables.tf
  ├── output.tf
  └── KEY-VAULT-MODULE-GUIDE.md
```

---

## Module Variables

### Primary Inputs

| Variable | Type | Default | Description |
|---|---|---|---|
| `resource_group_name` | `string` | *(required)* | Target resource group name |
| `location` | `string` | *(required)* | Azure region for all vaults |
| `key_vaults` | `map(object)` | `{}` | Map of Key Vaults to create |
| `common_tags` | `map(string)` | `{}` | Tags applied to all vaults |
| `tenant_id` | `string` | *(read from data.azurerm_client_config.current)* | Azure tenant ID (module reads tenant from data source; do not pass tenant_id) |

#### `key_vaults` Object Structure

Each key in the map becomes the vault name. Object contains:

```hcl
key_vaults = {
  "myvault" = {
    sku_name                      = "standard"
    public_network_access_enabled = false
    soft_delete_retention_days    = 90
    purge_protection_enabled      = true
    tags = {
      purpose = "application-secrets"
    }
  }
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `sku_name` | `string` | `"standard"` | Vault SKU: `standard` or `premium` |
| `public_network_access_enabled` | `bool` | `false` | Allow public access to vault |
| `soft_delete_retention_days` | `number` | `90` | Days to retain soft-deleted vaults (7-90) |
| `purge_protection_enabled` | `bool` | `true` | Prevent purge of vault even after soft delete |
| `tags` | `map(string)` | `{}` | Vault-specific tags |

---

## Module Outputs

| Output | Type | Description |
|---|---|---|
| `key_vaults` | `map(object)` | Map of all created vaults with `id`, `name`, `vault_uri` |
| `kv_tenant_id` | `string` | Azure tenant ID (for reference) |

### Output Structure

```hcl
key_vaults = {
  "myvault" = {
    id        = "/subscriptions/.../resourceGroups/rg/providers/Microsoft.KeyVault/vaults/myvault"
    name      = "myvault"
    vault_uri = "https://myvault.vault.azure.net/"
  }
}
```

---

## Usage Examples

### Example 1: Single Standard Key Vault

```hcl
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "app-secrets-vault" = {
      sku_name                      = "standard"
      public_network_access_enabled = false
      purge_protection_enabled      = true
    }
  }

  common_tags = {
    environment = "production"
    purpose     = "secrets-management"
  }
}

# Access vault URI
output "vault_uri" {
  value = module.kv.key_vaults["app-secrets-vault"].vault_uri
}
```

---

### Example 2: Multiple Vaults with Different Purposes

```hcl
module "kv_multi" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "app-secrets" = {
      sku_name                      = "standard"
      public_network_access_enabled = false
      purge_protection_enabled      = true
      tags = {
        purpose = "application-secrets"
      }
    }
    "encryption-keys" = {
      sku_name                      = "premium"  # Premium for HSM support
      public_network_access_enabled = false
      purge_protection_enabled      = true
      tags = {
        purpose     = "cmk-encryption"
        security    = "high"
      }
    }
    "certificates-vault" = {
      sku_name                      = "standard"
      public_network_access_enabled = false
      soft_delete_retention_days    = 30
      purge_protection_enabled      = false
      tags = {
        purpose = "tls-certificates"
      }
    }
  }

  common_tags = {
    environment = "production"
    managed_by  = "terraform"
    owner       = "security-team"
  }
}
```

---

### Example 3: Premium Vault with HSM-backed Keys (for CMK)

```hcl
module "kv_premium_cmk" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "cmk-vault" = {
      sku_name                      = "premium"  # Premium enables HSM
      public_network_access_enabled = false
      soft_delete_retention_days    = 90
      purge_protection_enabled      = true
      tags = {
        purpose = "hsm-cmk-keys"
        hsm     = "enabled"
      }
    }
  }

  common_tags = {
    environment = "production"
    compliance  = "pci-dss"
  }
}

# Use vault URI with Key Vault Key resource
resource "azurerm_key_vault_key" "storage_key" {
  name            = "storage-encryption-key"
  key_vault_id    = module.kv_premium_cmk.key_vaults["cmk-vault"].id
  key_type        = "RSA"
  key_size        = 4096
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# Use the key for storage CMK
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "secure-storage" = {
      cmk_enabled          = true
      cmk_key_vault_key_id = azurerm_key_vault_key.storage_key.id
    }
  }
}
```

---

### Example 4: Vaults Across Multiple Regions

```hcl
module "kv_regional" {
  for_each = toset(["eastus", "westus2"])

  source = "./modules/Key-Vaults"

  # Example: create a regional resource group per region (naming convention shown)
  resource_group_name = "rg-prod-${each.value}"
  location            = each.value

  key_vaults = {
    "secrets-${each.value}" = {
      sku_name                      = "standard"
      public_network_access_enabled = false
      purge_protection_enabled      = true
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

# Access regional vaults
output "east_vault_uri" {
  value = module.kv_regional["eastus"].key_vaults["secrets-eastus"].vault_uri
}

output "west_vault_uri" {
  value = module.kv_regional["westus2"].key_vaults["secrets-westus2"].vault_uri
}
```

---

### Example 5: Choose RBAC Authorization (no access policies)

Use `auth_type = "rbac"` per vault or set `default_auth_type = "rbac"` at module level to enable Azure RBAC for Key Vaults. When RBAC is used, do not supply `access_policies` for that vault — RBAC role assignments must be created separately (e.g., using the `Role-Assignment` module) and scoped to the Key Vault.

```hcl
module "kv_rbac" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "vault-with-rbac" = {
      sku_name = "standard"
      auth_type = "rbac"
      tags = { env = "prod" }
    }
  }

  common_tags = { managed_by = "terraform" }
}

# Create role assignment using Role-Assignment module or azurerm_role_assignment resource
module "kv_rbac_assignment" {
  source = "../modules/Role-Assignment"
  role_assignments = {
    "kv-reader" = {
      scope = module.kv_rbac.key_vaults["vault-with-rbac"].id
      role_definition_name = "Key Vault Reader"
      principal_id = data.azurerm_client_config.current.object_id
    }
  }
}
```

Note: `Key Vault Reader` is an example — choose appropriate role like `Key Vault Crypto Service Encryption User` or `Key Vault Secrets User` depending on the identity's purpose.

---

## Dynamicity & Scalability

| Aspect | Support |
|---|---|
| **Create multiple vaults** | ✅ Yes — via `key_vaults` map |
| **Per-vault SKU** | ✅ Yes — mix standard and premium |
| **Per-vault retention** | ✅ Yes — different soft-delete retention per vault |
| **Per-vault access control** | ✅ Yes — configure via access policies |
| **Per-vault tags** | ✅ Yes — custom + common tags merge |
| **Network access control** | ✅ Yes — per-vault public/private settings |
| **Backward compatibility** | ✅ Yes — legacy single-vault inputs supported |

---

### Why both single and multi resource patterns exist

This module originally supported a single Key Vault instance. To improve scalability and reduce repetition, the module was extended to accept a `key_vaults` map so you can create multiple vaults in one call with per-vault configuration. The legacy single-vault inputs (`key_vault_name`, `sku_name`, etc.) remain supported for backward compatibility but are deprecated — migrate to the `key_vaults` map when convenient.


## Integration with Other Modules

### With User-Assigned-Identity for Access Policies

```hcl
# Create UAI
module "app_identity" {
  source = "./modules/User-Assigned-Identity"

  identities = {
    myapp = {
      name           = "myapp-identity"
      resource_group = "rg-prod"
      location       = "eastus"
    }
  }
}

# Create Key Vault
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "app-vault" = {
      sku_name = "standard"
    }
  }
}

# Add access policy (using separate access_policy module or resource)
resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = module.kv.key_vaults["app-vault"].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.app_identity.identities["myapp"].principal_id

  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List"]
}
```

### With Storage Accounts for CMK

```hcl
# Create vault with HSM-enabled key
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "storage-cmk-vault" = {
      sku_name = "premium"
    }
  }
}

# Create CMK key
resource "azurerm_key_vault_key" "storage_cmk" {
  name         = "storage-key"
  key_vault_id = module.kv.key_vaults["storage-cmk-vault"].id
  key_type     = "RSA"
  key_size     = 4096
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# Use in storage
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = "rg-prod"
  location            = "eastus"

  storage_accounts = {
    "cmk-storage" = {
      cmk_enabled          = true
      cmk_key_vault_key_id = azurerm_key_vault_key.storage_cmk.id
    }
  }
}
```

### With AKS for Secrets and Certs

```hcl
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = "rg-prod"
  location            = "eastus"

  key_vaults = {
    "aks-vault" = {
      sku_name = "standard"
    }
  }
}

# Store secrets for AKS
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_pwd.result
  key_vault_id = module.kv.key_vaults["aks-vault"].id
}

# Reference in AKS module
module "aks" {
  source = "./modules/AKS-Private-Cluster"

  kv_id = module.kv.key_vaults["aks-vault"].id
  
  # ... other AKS config
}
```

---

## Best Practices

1. **Use Premium for HSM keys** — Only Premium tier supports HSM-backed keys for CMK
2. **Enable purge protection** — Prevent accidental deletion in production vaults
3. **Disable public access** — Set `public_network_access_enabled = false` for security
4. **Use consistent naming** — Include purpose (e.g., `app-secrets`, `cmk-keys`)
5. **Apply strict RBAC** — Use access policies to grant minimal required permissions
6. **Enable soft delete** — Retain deleted vaults for accidental recovery
7. **Monitor access** — Enable Key Vault logging for compliance audits
8. **Rotate keys regularly** — Implement key rotation policies
9. **Use separate vaults by purpose** — Secrets, certificates, encryption keys in separate vaults
10. **Tag for compliance** — Include compliance and owner tags

---

## Troubleshooting

### Issue: "Vault name is already taken"
**Solution:** Key Vault names must be globally unique. Use prefixes with environment/timestamp.

### Issue: "Purge not allowed"
**Solution:** If `purge_protection_enabled = true`, cannot immediately purge soft-deleted vault. Wait retention period or disable purge protection first.

### Issue: "Access Denied" when accessing vault
**Solution:** Ensure identity/principal has proper access policy with required permissions.

### Issue: "Cannot create Premium vault in region"
**Solution:** Premium SKU may not be available in all regions. Check [Azure availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=key-vault).

---

## Key Vault Names — Important Notes

- Must be 3-24 characters
- Alphanumeric and hyphens only
- Must start with letter, end with letter or digit
- Must be globally unique
- No consecutive hyphens

Example valid names:
- `app-secrets-prod`
- `encryption-keys-east`
- `cmk-vault-2024`

---

## Permissions Reference

### Common Key Permissions
- `Get`, `List` — Read access
- `Create`, `Import` — Create new keys
- `Delete`, `Purge` — Delete keys
- `Backup`, `Restore` — Backup/restore keys
- `Decrypt`, `Encrypt`, `UnwrapKey`, `WrapKey`, `Verify`, `Sign` — Cryptographic operations

### Common Secret Permissions
- `Get`, `List` — Read secrets
- `Set`, `Delete` — Create/delete secrets
- `Backup`, `Restore` — Backup/restore secrets

---

## Limitations & Considerations

- **Global uniqueness:** Key Vault names must be unique across entire Azure platform
- **Region availability:** Premium SKU not available in all regions
- **Access policies limit:** Max 1024 access policies per vault
- **Rate limiting:** API calls rate-limited (default ~2000 req/10s)
- **Key size limits:** RSA keys up to 4096-bit, ECC up to P-521
- **Soft delete mandatory:** Cannot disable soft delete; minimum 7 days retention

---

## Summary

The Key Vaults module provides a **robust, secure, and scalable way** to manage cryptographic keys, secrets, and certificates. Use the `key_vaults` map to create **multiple vaults** with **independent configurations**, **premium HSM support**, and **strict access control**. Perfect for multi-tier security, CMK encryption, and compliance-heavy workloads.

