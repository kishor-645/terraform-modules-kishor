# Terraform Modules – Complete Reference Guide

## 📚 Overview

This document provides a **complete reference** for all Terraform modules in this repository. Each module is fully dynamic, supports creating multiple resources, and includes comprehensive documentation with practical examples.

---

## 🎯 Quick Navigation

| Module | Purpose | Guide | Dynamicity | Multi-Resource |
|---|---|---|---|---|
| **RG** | Resource Groups | [RG-MODULE-GUIDE.md](./modules/RG/RG-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Vnet** | Virtual Networks & Subnets | [VNET-MODULE-GUIDE.md](./modules/Vnet/VNET-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Storage-Accounts** | Azure Storage | [STORAGE-MODULE-GUIDE.md](./modules/Storage-Accounts/STORAGE-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Key-Vaults** | Key Vault & Secrets | [KEY-VAULT-MODULE-GUIDE.md](./modules/Key-Vaults/KEY-VAULT-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Azure-Firewall** | Firewall & Policies | [azurefirewall-module-guide.md](./modules/Azure-Firewall/azurefirewall-module-guide.md) | ⭐⭐⭐ High | ✅ Yes |
| **PostgreSQL-Flexible-Server** | PostgreSQL DB | [POSTGRESQL-MODULE-GUIDE.md](./modules/PostgreSQL-Flexible-Server/POSTGRESQL-MODULE-GUIDE.md) | ⭐⭐ Medium | ⚠️ Single |
| **AKS-Private-Cluster** | Kubernetes Cluster | [AKS-MODULE-GUIDE.md](./modules/AKS-Private-Cluster/AKS-MODULE-GUIDE.md) | ⭐⭐⭐ High | ⚠️ Single |
| **Azure-Container-Registries** | Container Registry | [ACR-MODULE-GUIDE.md](./modules/Azure-Container-Registries/ACR-MODULE-GUIDE.md) | ⭐⭐ Medium | ⚠️ Single |
| **App-Gateway** | Application Gateway | [APP-GATEWAY-MODULE-GUIDE.md](./modules/App-Gateway/APP-GATEWAY-MODULE-GUIDE.md) | ⭐⭐⭐ High | ⚠️ Single |
| **Azure-Frontdoor** | Front Door CDN | [FRONTDOOR-MODULE-GUIDE.md](./modules/Azure-Frontdoor/FRONTDOOR-MODULE-GUIDE.md) | ⭐⭐ Medium | ⚠️ Single |
| **Azure-Private-Endpoints** | Private Endpoints | [PE-MODULE-GUIDE.md](./modules/Azure-Private-Endpoints/PE-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Log-Analytics-Workspace** | Monitoring & Logging | [LAW-MODULE-GUIDE.md](./modules/Log-Analytics-Workspace/LAW-MODULE-GUIDE.md) | ⭐⭐ Medium | ⚠️ Single |
| **Diagnostic-Settings** | Resource Diagnostics | [DIAG-MODULE-GUIDE.md](./modules/Diagnostic-Settings/DIAG-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **User-Assigned-Identity** | Managed Identities | [UAI-MODULE-GUIDE.md](./modules/User-Assigned-Identity/UAI-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Role-Assignment** | RBAC Assignments | [RBAC-MODULE-GUIDE.md](./modules/Role-Assignment/RBAC-MODULE-GUIDE.md) | ⭐⭐⭐ High | ✅ Yes |
| **Linux-Virtual-Machines** | Linux VMs | [LINUX-VM-MODULE-GUIDE.md](./modules/Linux-Virtual-Machines/LINUX-VM-MODULE-GUIDE.md) | ⭐⭐ Medium | ✅ Yes |
| **Windows-Virtual-Machines** | Windows VMs | [WINDOWS-VM-MODULE-GUIDE.md](./modules/Windows-Virtual-Machines/WINDOWS-VM-MODULE-GUIDE.md) | ⭐⭐ Medium | ✅ Yes |
| **Private-DNS-Zone** | Private DNS | [PRIVATE-DNS-MODULE-GUIDE.md](./modules/Private-DNS-Zone/PRIVATE-DNS-MODULE-GUIDE.md) | ⭐⭐ Medium | ⚠️ Single |
| **Vnet-peering** | VNet Peering | [VNET-PEERING-MODULE-GUIDE.md](./modules/Vnet-peering/VNET-PEERING-MODULE-GUIDE.md) | ⭐⭐ Medium | ✅ Yes |

---

## 🔧 Core Modules (Most Used)

### 1. **Resource Groups (RG)**
The foundation of all Azure deployments. Create single or multiple resource groups with dynamic tagging.

**Features:**
- Create multiple RGs in one call
- Per-RG and common tags
- Clean outputs for reference in other modules

**Example:**
```hcl
module "rg" {
  source = "./modules/RG"

  resource_groups = {
    "rg-prod" = {
      location = "eastus"
      tags = { env = "production" }
    }
    "rg-dev" = {
      location = "eastus"
      tags = { env = "development" }
    }
  }

  common_tags = {
    managed_by = "terraform"
  }
}
```

[📖 Full RG Guide](./modules/RG/RG-MODULE-GUIDE.md)

---

### 2. **Virtual Networks (Vnet)**
Create hub-and-spoke VNets with subnets, optional DDoS protection, and flexible networking topology.

**Features:**
- Multiple VNets with subnets
- DDoS protection (conditional)
- Hub-and-spoke design support
- Service endpoints configuration

**Example:**
```hcl
module "vnet" {
  source = "./modules/Vnet"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  vnets = {
    "hub-vnet" = {
      name           = "hub-vnet"
      address_space  = ["10.0.0.0/16"]
      enable_ddos_protection = true
      subnets = {
        "gateway-subnet" = {
          name           = "GatewaySubnet"
          address_prefix = "10.0.1.0/24"
        }
        "app-subnet" = {
          name           = "app-subnet"
          address_prefix = "10.0.2.0/24"
        }
      }
    }
  }
}
```

[📖 Full Vnet Guide](./modules/Vnet/VNET-MODULE-GUIDE.md)

---

### 3. **Storage Accounts**
Enterprise-grade storage with CMK encryption, multiple replication options, and private endpoints support.

**Features:**
- Multiple storage accounts with different tiers
- Customer Managed Key (CMK) support
- Infrastructure encryption (double-encryption)
- Per-account configuration

**Example:**
```hcl
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  storage_accounts = {
    "appdata" = {
      account_tier             = "Standard"
      account_replication_type = "GRS"
      cmk_enabled              = true
      cmk_key_vault_key_id     = azurerm_key_vault_key.storage_key.id
    }
    "backups" = {
      account_tier             = "Standard"
      account_replication_type = "RAGRS"
    }
  }

  common_tags = {
    environment = "production"
  }
}
```

[📖 Full Storage Guide](./modules/Storage-Accounts/STORAGE-MODULE-GUIDE.md)

---

### 4. **Key Vaults**
Secure key and secret management with HSM support, access policies, and soft delete protection.

**Features:**
- Multiple Key Vaults with independent configurations
- Premium SKU for HSM-backed keys
- Purge protection and soft delete
- Access policy management

**Example:**
```hcl
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  key_vaults = {
    "secrets-vault" = {
      sku_name                 = "standard"
      public_network_access_enabled = false
      purge_protection_enabled = true
    }
    "cmk-vault" = {
      sku_name = "premium"  # For HSM
    }
  }

  common_tags = {
    security = "high"
  }
}
```

[📖 Full Key Vault Guide](./modules/Key-Vaults/KEY-VAULT-MODULE-GUIDE.md)

---

### 5. **Azure Firewall**
Advanced firewall with policies, NAT rules, network rules, and application rules.

**Features:**
- Firewall policy management
- NAT, network, and application rules
- TLS inspection (Premium)
- IDPS and threat intelligence
- Public IP and subnet configuration

**Example:**
```hcl
module "firewall" {
  source = "./modules/Azure-Firewall"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  firewall_name = "fw-prod"
  firewall_policy_name = "fw-policy-prod"

  # NAT rules, network rules, application rules configuration
  nat_rules = { ... }
  network_rules = { ... }
  application_rules = { ... }
}
```

[📖 Full Firewall Guide](./modules/Azure-Firewall/azurefirewall-module-guide.md)

---

## 🏗️ Infrastructure Modules

### **AKS (Private Cluster)**
Enterprise-grade Kubernetes with private networking, RBAC, and CMK support for DES.

**Features:**
- Private AKS cluster
- Multiple node pools
- Role assignments
- DES for CMK disk encryption
- Private DNS zone integration

**Example:**
```hcl
module "aks" {
  source = "./modules/AKS-Private-Cluster"

  resource_group_name   = module.rg.resource_groups["rg-prod"].name
  location              = "eastus"
  aks_cluster_name      = "aks-prod"
  private_cluster_enabled = true

  cmk_enabled = true
  cmk_key_vault_key_id = azurerm_key_vault_key.des_key.id

  node_pools = {
    system = {
      vm_size = "Standard_D2s_v3"
      node_count = 3
    }
  }
}
```

[📖 Full AKS Guide](./modules/AKS-Private-Cluster/AKS-MODULE-GUIDE.md)

---

### **PostgreSQL Flexible Server**
Managed PostgreSQL with high availability, CMK support, and Azure AD authentication.

**Features:**
- HA configuration
- CMK encryption
- Azure AD authentication
- Backup and restore
- Zone redundancy

**Example:**
```hcl
module "postgresql" {
  source = "./modules/PostgreSQL-Flexible-Server"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  server_name = "postgres-prod"
  sku_name    = "B_Standard_B2s"

  cmk_enabled              = true
  cmk_key_vault_key_id     = azurerm_key_vault_key.db_cmk.id
  geo_redundant_backup_enabled = true
}
```

[📖 Full PostgreSQL Guide](./modules/PostgreSQL-Flexible-Server/POSTGRESQL-MODULE-GUIDE.md)

---

### **Azure Container Registry (ACR)**
Managed container registry with network rules, managed identity, and CMK support.

**Features:**
- Multiple SKUs
- Network rules and private endpoints
- Managed identity support
- CMK encryption

**Example:**
```hcl
module "acr" {
  source = "./modules/Azure-Container-Registries"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  registry_name = "acrprod"
  sku           = "Premium"
  admin_enabled = false
}
```

[📖 Full ACR Guide](./modules/Azure-Container-Registries/ACR-MODULE-GUIDE.md)

---

## 🔐 Security & Access Modules

### **User-Assigned Identities (UAI)**
Managed identities for services with dynamic role assignment support.

**Features:**
- Create multiple identities
- Assign roles to identities
- Integration with all Azure services

**Example:**
```hcl
module "identities" {
  source = "./modules/User-Assigned-Identity"

  identities = {
    app = {
      name           = "app-identity"
      resource_group = "rg-prod"
      location       = "eastus"
    }
    aks = {
      name           = "aks-identity"
      resource_group = "rg-prod"
      location       = "eastus"
    }
  }

  role_assignments = {
    app_reader = {
      principal_id         = module.identities.identities["app"].principal_id
      role_definition_name = "Reader"
      scope                = module.kv.key_vaults["secrets-vault"].id
    }
  }
}
```

[📖 Full UAI Guide](./modules/User-Assigned-Identity/UAI-MODULE-GUIDE.md)

---

### **Role Assignments (RBAC)**
Flexible RBAC module for assigning roles to any principal at any scope.

**Features:**
- Support role name or ID
- Multiple assignments in one call
- Any scope (subscription, RG, resource)

**Example:**
```hcl
module "rbac" {
  source = "./modules/Role-Assignment"

  role_assignments = {
    app_vault_access = {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "Key Vault Secrets Officer"
      scope                = module.kv.key_vaults["secrets-vault"].id
    }
    aks_acr_pull = {
      principal_id         = module.aks.kubelet_identity.object_id
      role_definition_name = "AcrPull"
      scope                = module.acr.registry.id
    }
  }
}
```

[📖 Full RBAC Guide](./modules/Role-Assignment/RBAC-MODULE-GUIDE.md)

---

## 📡 Networking Modules

### **Private Endpoints**
Secure private connectivity to Azure services without public internet exposure.

**Features:**
- Support for all Azure PaaS services
- Private DNS zone integration
- NIC configuration

**Example:**
```hcl
module "private_endpoints" {
  source = "./modules/Azure-Private-Endpoints"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  private_endpoints = {
    storage_pe = {
      resource_id       = module.storage.storage_accounts["appdata"].id
      subresource_names = ["blob"]
      subnet_id         = module.vnet.subnets["private"].id
    }
    kv_pe = {
      resource_id       = module.kv.key_vaults["secrets-vault"].id
      subresource_names = ["vault"]
      subnet_id         = module.vnet.subnets["private"].id
    }
  }
}
```

[📖 Full Private Endpoints Guide](./modules/Azure-Private-Endpoints/PE-MODULE-GUIDE.md)

---

### **Application Gateway**
Layer 7 load balancing with WAF, SSL termination, and managed identity support.

**Features:**
- WAF policies
- Multi-site hosting
- SSL/TLS termination
- Managed identity for Key Vault certs

**Example:**
```hcl
module "app_gateway" {
  source = "./modules/App-Gateway"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  gateway_name = "appgw-prod"
  sku_name     = "WAF_v2"
  capacity     = 2

  waf_enabled = true
  waf_mode    = "Prevention"
}
```

[📖 Full App Gateway Guide](./modules/App-Gateway/APP-GATEWAY-MODULE-GUIDE.md)

---

### **Azure Front Door**
Global load balancing with automatic failover and CDN capabilities.

**Features:**
- Multi-region origin groups
- Route rules and policies
- Traffic acceleration

**Example:**
```hcl
module "frontdoor" {
  source = "./modules/Azure-Frontdoor"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  profile_name = "fd-prod"
  sku          = "Premium"
}
```

[📖 Full Front Door Guide](./modules/Azure-Frontdoor/FRONTDOOR-MODULE-GUIDE.md)

---

## 📊 Monitoring & Compliance Modules

### **Log Analytics Workspace**
Central logging and monitoring hub for all resources.

**Features:**
- Retention and SKU configuration
- Linked services
- Integration with Sentinel

**Example:**
```hcl
module "law" {
  source = "./modules/Log-Analytics-Workspace"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  workspace_name       = "law-prod"
  retention_in_days    = 90
  daily_quota_gb       = 10
}
```

[📖 Full LAW Guide](./modules/Log-Analytics-Workspace/LAW-MODULE-GUIDE.md)

---

### **Diagnostic Settings**
Route resource logs and metrics to Log Analytics, Event Hub, or Storage.

**Features:**
- Multiple destination types
- Category selection
- Retention policies

**Example:**
```hcl
module "diagnostics" {
  source = "./modules/Diagnostic-Settings"

  diagnostic_settings = {
    aks_diag = {
      resource_id        = module.aks.cluster.id
      log_analytics_workspace_id = module.law.workspace_id
      log_categories     = ["kube-apiserver", "kube-controller-manager"]
    }
    storage_diag = {
      resource_id        = module.storage.storage_accounts["appdata"].id
      log_analytics_workspace_id = module.law.workspace_id
    }
  }
}
```

[📖 Full Diagnostics Guide](./modules/Diagnostic-Settings/DIAG-MODULE-GUIDE.md)

---

## 💻 Compute Modules

### **Linux Virtual Machines**
Linux VMs with NIC, NSG, optional public IP, and extensions support.

**Features:**
- Multiple VMs in one call
- Custom image support
- Extensions and diagnostics

**Example:**
```hcl
module "linux_vms" {
  source = "./modules/Linux-Virtual-Machines"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  vms = {
    app-vm = {
      size     = "Standard_D2s_v3"
      image    = "UbuntuServer"
      username = "azureuser"
    }
  }
}
```

[📖 Full Linux VM Guide](./modules/Linux-Virtual-Machines/LINUX-VM-MODULE-GUIDE.md)

---

### **Windows Virtual Machines**
Windows VMs with RDP, Windows-specific extensions, and auto-update support.

**Features:**
- Windows OS support
- Domain join capability
- Windows Update management

**Example:**
```hcl
module "windows_vms" {
  source = "./modules/Windows-Virtual-Machines"

  resource_group_name = module.rg.resource_groups["rg-prod"].name
  location            = "eastus"

  vms = {
    db-vm = {
      size     = "Standard_E2s_v3"
      image    = "WindowsServer2022"
      admin_username = "azureadmin"
    }
  }
}
```

[📖 Full Windows VM Guide](./modules/Windows-Virtual-Machines/WINDOWS-VM-MODULE-GUIDE.md)

---

## 🌐 DNS & Peering Modules

### **Private DNS Zone**
Private DNS for internal name resolution within VNets.

**Features:**
- Multiple DNS zones
- VNet links and auto-registration
- Records management

**Example:**
```hcl
module "private_dns" {
  source = "./modules/Private-DNS-Zone"

  resource_group_name = module.rg.resource_groups["rg-prod"].name

  dns_zones = {
    "internal.company.com" = {
      vnet_links = {
        hub_link = {
          virtual_network_id = module.vnet.vnets["hub"].id
        }
      }
    }
  }
}
```

[📖 Full Private DNS Guide](./modules/Private-DNS-Zone/PRIVATE-DNS-MODULE-GUIDE.md)

---

### **VNet Peering**
Connect VNets in hub-and-spoke topology.

**Features:**
- Hub-to-spoke peering
- Traffic forwarding
- Gateway transit

**Example:**
```hcl
module "vnet_peering" {
  source = "./modules/Vnet-peering"

  resource_group_name = module.rg.resource_groups["rg-prod"].name

  peerings = {
    hub_to_spoke1 = {
      virtual_network_1_id = module.vnet.vnets["hub"].id
      virtual_network_2_id = module.vnet.vnets["spoke1"].id
      traffic_forwarding_enabled = true
    }
  }
}
```

[📖 Full VNet Peering Guide](./modules/Vnet-peering/VNET-PEERING-MODULE-GUIDE.md)

---

## 🏭 Complete Example: Multi-Tier Enterprise Architecture

```hcl
# Create Resource Groups
module "rg" {
  source = "./modules/RG"

  resource_groups = {
    "rg-prod-network" = { location = "eastus" }
    "rg-prod-app"     = { location = "eastus" }
    "rg-prod-data"    = { location = "eastus" }
  }

  common_tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}

# Create Networking
module "vnet" {
  source = "./modules/Vnet"

  resource_group_name = module.rg.resource_groups["rg-prod-network"].name
  location            = "eastus"

  vnets = {
    hub = { ... }
    spoke = { ... }
  }
}

# Create Storage with CMK
module "storage" {
  source = "./modules/Storage-Accounts"

  resource_group_name = module.rg.resource_groups["rg-prod-data"].name
  location            = "eastus"

  storage_accounts = {
    data = {
      cmk_enabled          = true
      cmk_key_vault_key_id = azurerm_key_vault_key.storage.id
    }
  }
}

# Create Key Vaults
module "kv" {
  source = "./modules/Key-Vaults"

  resource_group_name = module.rg.resource_groups["rg-prod-app"].name
  location            = "eastus"

  key_vaults = {
    secrets    = { sku_name = "standard" }
    encryption = { sku_name = "premium" }
  }
}

# Create AKS with CMK
module "aks" {
  source = "./modules/AKS-Private-Cluster"

  resource_group_name = module.rg.resource_groups["rg-prod-app"].name
  location            = "eastus"

  cmk_enabled          = true
  cmk_key_vault_key_id = azurerm_key_vault_key.des.id
}

# Create Firewall
module "firewall" {
  source = "./modules/Azure-Firewall"

  resource_group_name = module.rg.resource_groups["rg-prod-network"].name
  location            = "eastus"
}

# Create Private Endpoints
module "pe" {
  source = "./modules/Azure-Private-Endpoints"

  resource_group_name = module.rg.resource_groups["rg-prod-app"].name
  location            = "eastus"

  private_endpoints = {
    storage_pe = { ... }
    kv_pe      = { ... }
  }
}

# Create Monitoring
module "law" {
  source = "./modules/Log-Analytics-Workspace"

  resource_group_name = module.rg.resource_groups["rg-prod-app"].name
  location            = "eastus"
}
```

---

## 📋 Dynamicity Legend

- **⭐⭐⭐ High:** Full multi-resource support, extensive per-resource configuration options
- **⭐⭐ Medium:** Multi-resource or extensive per-resource configuration, but not both
- **⭐ Low:** Single resource or very limited configuration

---

## ✅ Best Practices Across All Modules

1. **Always use the `resource_groups` map** for RG module, not legacy inputs
2. **Apply common tags** — Use `common_tags` variable for consistency
3. **Enable CMK** for sensitive data (Storage, PostgreSQL, AKS, ACR)
4. **Disable public access** by default — Use Private Endpoints instead
5. **Use User-Assigned Identities** for service-to-service authentication
6. **Implement network segmentation** — Separate subnets by tier
7. **Enable monitoring** — Configure Diagnostic Settings for all resources
8. **Use Private Endpoints** for all PaaS service access
9. **Enable purge protection** on Key Vaults
10. **Tag resources consistently** — Include environment, owner, cost-center, purpose

---

## 🔗 Integration Patterns

### Pattern 1: Hub-and-Spoke with Firewall

```
Hub VNet → Firewall → Internet
    ↓
Spoke VNets (Peered) → Workloads
```

**Modules:** Vnet, Vnet-peering, Azure-Firewall

### Pattern 2: Private Workload Access

```
Private Endpoint → Storage/KV/Database (No Public Access)
    ↓
VNet with Private Subnet → Application
```

**Modules:** Vnet, Private-Endpoints, Storage, Key-Vaults

### Pattern 3: Multi-Layer Security

```
App Gateway + WAF → AKS → PostgreSQL (Private)
    ↓
All with CMK encryption + Private Endpoints
```

**Modules:** App-Gateway, AKS, PostgreSQL, Private-Endpoints, User-Assigned-Identity

### Pattern 4: Global Distribution

```
Azure Front Door → App Gateway (East) + App Gateway (West)
    ↓
Regional AKS + Storage + Database
```

**Modules:** Azure-Frontdoor, App-Gateway, AKS, Storage, PostgreSQL

---

## 📞 Support & Resources

- **Module Guides:** Each module has a detailed `*-MODULE-GUIDE.md` file
- **Examples:** See usage examples in each module's guide
- **Terraform Docs:** [Terraform Registry - azurerm Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **Azure Docs:** [Azure Resource Manager Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

---

## 🚀 Getting Started

1. **Read the RG module guide** — Understand how to create resource groups
2. **Read the Vnet module guide** — Set up networking foundation
3. **Choose your workload module** — AKS, Storage, Database, etc.
4. **Refer to integration patterns** — Connect modules together
5. **Apply common tags** — Use consistent tagging across all modules

---

**Last Updated:** December 2024  
**Terraform Version:** >= 1.0  
**Azurerm Provider:** >= 3.x

