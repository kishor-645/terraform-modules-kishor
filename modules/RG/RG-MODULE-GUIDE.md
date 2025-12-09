# Resource Groups (RG) Module Guide

## Overview

The **Resource Groups (RG)** module is a flexible, reusable Terraform module for creating one or more Azure Resource Groups with dynamic tagging and configuration support. This module is **fully dynamic** and allows you to create multiple resource groups in a single module invocation, each with its own location and tags.

### Key Features
- ✅ Create **multiple resource groups** in a single call via a map input
- ✅ **Dynamic tagging** — apply common tags to all RGs or per-RG tags
- ✅ **Backward compatible** — supports legacy single-RG inputs (deprecated)
- ✅ **Clean outputs** — export all created RGs with their IDs and properties

---

## Directory Structure

```
modules/
└── RG/
    ├── main.tf          # Resource definitions
    ├── variables.tf     # Input variables
    ├── output.tf        # Output values
    └── RG-MODULE-GUIDE.md
```

---

## Module Variables

### Primary Input: `resource_groups` (Map)

| Variable | Type | Default | Description |
|---|---|---|---|
| `resource_groups` | `map(object)` | `{}` | Map of resource groups to create. Each key is the RG name. |
| `common_tags` | `map(string)` | `{}` | Common tags applied to all resource groups |

#### `resource_groups` Object Structure

```hcl
resource_groups = {
  "rg-name" = {
    location = "eastus"
    tags = {
      environment = "prod"
      owner       = "platform-team"
    }
  }
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | *(required)* | Azure region where the RG will be created (e.g., "eastus", "westus2") |
| `tags` | `map(string)` | `{}` | Optional tags specific to this RG. Merged with `common_tags`. |

---

## Module Outputs

| Output | Type | Description |
|---|---|---|
| `resource_groups` | `map(object)` | Map of all created RGs with `id`, `name`, and `location` |

### Output Structure

```hcl
{
  "rg-prod" = {
    id       = "/subscriptions/xxx/resourceGroups/rg-prod"
    name     = "rg-prod"
    location = "eastus"
  }
}
```

---

## Usage Examples

### Example 1: Create a Single Resource Group

```hcl
module "rg_single" {
  source = "./modules/RG"

  resource_groups = {
    "rg-prod" = {
      location = "eastus"
      tags = {
        environment = "production"
      }
    }
  }

  common_tags = {
    project     = "my-app"
    managed_by  = "terraform"
  }
}
```

**Output:**
```
resource_groups = {
  "rg-prod" = {
    id       = "/subscriptions/.../resourceGroups/rg-prod"
    name     = "rg-prod"
    location = "eastus"
  }
}
```

---

### Example 2: Create Multiple Resource Groups Across Regions

```hcl
module "rg_multi" {
  source = "./modules/RG"

  resource_groups = {
    "rg-prod-east" = {
      location = "eastus"
      tags = {
        environment = "production"
        region      = "east"
      }
    }
    "rg-prod-west" = {
      location = "westus2"
      tags = {
        environment = "production"
        region      = "west"
      }
    }
    "rg-dev" = {
      location = "eastus"
      tags = {
        environment = "development"
      }
    }
    "rg-test" = {
      location = "westus2"
      tags = {
        environment = "test"
      }
    }
  }

  common_tags = {
    project    = "my-enterprise-app"
    managed_by = "terraform"
    owner      = "platform-team"
  }
}
```

**Output:**
```
resource_groups = {
  "rg-prod-east" = { id = "...", name = "rg-prod-east", location = "eastus" }
  "rg-prod-west" = { id = "...", name = "rg-prod-west", location = "westus2" }
  "rg-dev"       = { id = "...", name = "rg-dev", location = "eastus" }
  "rg-test"      = { id = "...", name = "rg-test", location = "westus2" }
}
```

---

### Example 3: Use RG Output in Other Modules

```hcl
# Create resource groups
module "rg" {
  source = "./modules/RG"

  resource_groups = {
    "rg-prod" = {
      location = "eastus"
    }
    "rg-backup" = {
      location = "westus2"
    }
  }

  common_tags = {
    managed_by = "terraform"
  }
}

# Reference RGs in other modules
module "vnet" {
  source = "./modules/Vnet"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = module.rg.resource_groups["rg-prod"].location
  
  # ... other vnet config
}

module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = module.rg.resource_groups["rg-backup"].name
  location            = module.rg.resource_groups["rg-backup"].location

  # ... other storage config
}
```

---

## Dynamicity & Scalability

| Aspect | Support |
|---|---|
| **Create multiple RGs** | ✅ Yes — via `resource_groups` map |
| **Per-RG tags** | ✅ Yes — each RG can have unique tags |
| **Common tags** | ✅ Yes — applied to all RGs automatically |
| **Dynamic regions** | ✅ Yes — each RG can be in a different location |
| **Backward compatibility** | ✅ Yes — old single-RG inputs still work |

---

## Integration with Other Modules

The RG module output can be referenced by any other module to target a specific resource group:

```hcl
# Pass RG name to other modules
module "storage" {
  source = "./modules/Storage-Accounts"
  
  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = module.rg.resource_groups["rg-prod"].location
  
  storage_accounts = { ... }
}

module "keyvault" {
  source = "./modules/Key-Vaults"
  
  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = module.rg.resource_groups["rg-prod"].location
  
  key_vaults = { ... }
}
```

---

## Best Practices

1. **Use meaningful RG names** — Include environment, region, or purpose (e.g., `rg-prod-east-app`)
2. **Apply common tags** — Use `common_tags` for consistency (project, owner, managed_by, cost-center)
3. **Organize by environment/region** — Create separate RGs for prod/dev/test and by region if multi-region
4. **Avoid dynamic RG names** — Use predictable, static names to avoid accidental deletions
5. **Reference outputs properly** — Always use `module.rg.resource_groups["key"].name` to avoid hardcoding

---

## Backward Compatibility (Deprecated Inputs)

The module still accepts legacy single-RG inputs for backward compatibility. However, these are **deprecated** and should not be used in new code.

```hcl
# ❌ OLD WAY (deprecated)
module "rg_old" {
  source = "./modules/RG"

  resource_group_name = "my-rg"
  location            = "eastus"
}

# ✅ NEW WAY (recommended)
module "rg_new" {
  source = "./modules/RG"

  resource_groups = {
    "my-rg" = {
      location = "eastus"
    }
  }
}
```

---

## Troubleshooting

### Issue: "Resource group already exists"
**Solution:** Ensure RG names are globally unique within Azure. Prefix with environment/region.

### Issue: Accessing a specific RG in outputs
```hcl
# Get a specific RG output
rg_id       = module.rg.resource_groups["rg-prod"].id
rg_name     = module.rg.resource_groups["rg-prod"].name
rg_location = module.rg.resource_groups["rg-prod"].location
```

### Issue: Tags not being applied
Ensure `common_tags` are provided and RGs are properly referenced:
```hcl
common_tags = {
  environment = "prod"
  managed_by  = "terraform"
}
```

---

## Limitations & Considerations

- **RG name uniqueness:** Must be unique within the Azure subscription
- **Region availability:** Verify the specified location is available in your subscription
- **Tag length:** Tag keys and values have Azure-imposed character limits
- **No RG deletion:** Removing an RG from the map will trigger a destroy. Be cautious!

---

## Summary

The RG module provides a **simple, flexible, and scalable way** to create and manage Azure Resource Groups. Use the `resource_groups` map to create **one or many** RGs with **custom tags**, and leverage the clean outputs to reference them in dependent modules.

