<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# see i crated this ACR module i want some examples like how we can use this module with diff diff capability or scenario like that i need some example terraform codes for root module call. it should be in simple way.

resource "azurerm_container_registry" "acr" {
name                         = var.acr_name
resource_group_name          = var.resource_group_name
location                     = var.location
sku                          = var.sku
admin_enabled                = var.admin_enabled
public_network_access_enabled = var.public_network_access_enabled

# Optional tags (fully dynamic)

tags = var.tags

# Optional customer-managed key (CMK)

# This will be created only when `encryption_key_vault_key_id` is provided.

dynamic "encryption" {
for_each = var.encryption_key_vault_key_id != null ? [var.encryption_key_vault_key_id] : []
content {
key_vault_key_id = encryption.value
}
}

# Optional user-assigned identity used to access the key vault for CMK

dynamic "identity" {
for_each = var.encryption_identity_id != null ? [var.encryption_identity_id] : []
content {
type         = "UserAssigned"
identity_ids = [identity.value]
}
}
}

# Diagnostic settings: optional, created only when a Log Analytics workspace id is provided

resource "azurerm_monitor_diagnostic_setting" "acr" {
count = var.log_analytics_workspace_id != null ? 1 : 0

name                       = "diag-\${var.acr_name}"
target_resource_id         = azurerm_container_registry.acr.id
log_analytics_workspace_id = var.log_analytics_workspace_id

enabled_log {
category = "ContainerRegistryRepositoryEvents"
}

enabled_log {
category = "ContainerRegistryLoginEvents"
}

enabled_metric {
category = "AllMetrics"
}
}

Perfect! Here are simple, practical examples showing how to use your ACR module in different scenarios. Each example demonstrates a specific capability or use case.[^1][^2][^3]

## ACR Module Usage Examples

### Example 1: Basic ACR (Development/Testing)

**Scenario:** Simple ACR for dev/test with admin access enabled[^1]

```hcl
module "acr_dev" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrdevtest001"
  resource_group_name           = "rg-dev"
  location                      = "eastus"
  sku                           = "Basic"
  admin_enabled                 = true
  public_network_access_enabled = true

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Output
output "acr_login_server" {
  value = module.acr_dev.login_server
}
```


***

### Example 2: Standard ACR for Production (No Admin)

**Scenario:** Production ACR with service principal authentication[^2][^1]

```hcl
module "acr_prod" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrprod001"
  resource_group_name           = "rg-prod"
  location                      = "eastus"
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  tags = {
    Environment = "Production"
    CostCenter  = "Engineering"
  }
}

# Service Principal for CI/CD
resource "azurerm_role_assignment" "acr_push" {
  scope                = module.acr_prod.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.cicd.object_id
}
```


***

### Example 3: Premium ACR with Customer-Managed Key (CMK)

**Scenario:** Enterprise ACR with encryption using Key Vault CMK[^3]

```hcl
# Key Vault for CMK
resource "azurerm_key_vault" "acr" {
  name                = "kv-acr-cmk"
  resource_group_name = "rg-security"
  location            = "eastus"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  purge_protection_enabled   = true
  soft_delete_retention_days = 7
}

# User Assigned Identity for ACR
resource "azurerm_user_assigned_identity" "acr" {
  name                = "id-acr-cmk"
  resource_group_name = "rg-security"
  location            = "eastus"
}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "acr" {
  key_vault_id = azurerm_key_vault.acr.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.acr.principal_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

# Key Vault Key
resource "azurerm_key_vault_key" "acr" {
  name         = "acr-encryption-key"
  key_vault_id = azurerm_key_vault.acr.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.acr]
}

# ACR with CMK
module "acr_cmk" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrpremium001"
  resource_group_name           = "rg-prod"
  location                      = "eastus"
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false

  # CMK Encryption
  encryption_key_vault_key_id = azurerm_key_vault_key.acr.id
  encryption_identity_id      = azurerm_user_assigned_identity.acr.id

  tags = {
    Environment = "Production"
    Security    = "High"
    Compliance  = "PCI-DSS"
  }
}
```


***

### Example 4: ACR with Diagnostic Logs (Monitoring)

**Scenario:** ACR with Log Analytics for audit and monitoring[^3]

```hcl
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "law-monitoring"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ACR with Diagnostics
module "acr_monitored" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrmonitored001"
  resource_group_name           = "rg-prod"
  location                      = "eastus"
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  # Enable diagnostic logs
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  tags = {
    Environment = "Production"
    Monitoring  = "Enabled"
  }
}
```


***

### Example 5: Private ACR with Private Endpoint

**Scenario:** Secure ACR accessible only via private endpoint[^4][^2]

```hcl
# VNet and Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-prod"
  resource_group_name = "rg-network"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "subnet-private-endpoints"
  resource_group_name  = "rg-network"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private ACR
module "acr_private" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrprivate001"
  resource_group_name           = "rg-prod"
  location                      = "eastus"
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false

  tags = {
    Environment = "Production"
    Network     = "Private"
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr"
  resource_group_name = "rg-network"
  location            = "eastus"
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = module.acr_private.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = "rg-network"
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-dns-link"
  resource_group_name   = "rg-network"
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
```


***

### Example 6: Multi-Region ACR Setup

**Scenario:** Separate ACR in each region for AKS clusters[^2]

```hcl
# East US ACR
module "acr_eastus" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acreastus001"
  resource_group_name           = "rg-eastus"
  location                      = "eastus"
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  log_analytics_workspace_id = azurerm_log_analytics_workspace.eastus.id

  tags = {
    Environment = "Production"
    Region      = "EastUS"
  }
}

# West US ACR
module "acr_westus" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrwestus001"
  resource_group_name           = "rg-westus"
  location                      = "westus"
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  log_analytics_workspace_id = azurerm_log_analytics_workspace.westus.id

  tags = {
    Environment = "Production"
    Region      = "WestUS"
  }
}

# AKS can pull from regional ACR
resource "azurerm_role_assignment" "aks_eastus_acr" {
  scope                = module.acr_eastus.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_eastus.kubelet_identity[^0].object_id
}
```


***

### Example 7: Complete AKS + ACR Integration

**Scenario:** AKS cluster with ACR pull permissions[^2]

```hcl
# ACR
module "acr" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acraksprod001"
  resource_group_name           = "rg-aks-prod"
  location                      = "eastus"
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  tags = {
    Environment = "Production"
    Workload    = "AKS"
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-prod"
  resource_group_name = "rg-aks-prod"
  location            = "eastus"
  dns_prefix          = "aks-prod"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[^0].object_id
}

# Output ACR details for AKS
output "acr_login_server" {
  value = module.acr.login_server
}
```


***

### Example 8: ACR Without Any Optional Features

**Scenario:** Minimal ACR configuration[^1]

```hcl
module "acr_minimal" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrminimal001"
  resource_group_name           = "rg-test"
  location                      = "eastus"
  sku                           = "Basic"
  admin_enabled                 = true
  public_network_access_enabled = true

  tags = {
    Environment = "Test"
  }
}
```


***

### Example 9: ACR with All Features (Premium)

**Scenario:** Enterprise ACR with all security features[^3][^2]

```hcl
# Prerequisites
data "azurerm_client_config" "current" {}

resource "azurerm_log_analytics_workspace" "acr" {
  name                = "law-acr"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_key_vault" "acr" {
  name                       = "kv-acr-enterprise"
  resource_group_name        = "rg-security"
  location                   = "eastus"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
}

resource "azurerm_user_assigned_identity" "acr" {
  name                = "id-acr-enterprise"
  resource_group_name = "rg-security"
  location            = "eastus"
}

resource "azurerm_key_vault_access_policy" "acr" {
  key_vault_id = azurerm_key_vault.acr.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.acr.principal_id

  key_permissions = ["Get", "UnwrapKey", "WrapKey"]
}

resource "azurerm_key_vault_key" "acr" {
  name         = "acr-key"
  key_vault_id = azurerm_key_vault.acr.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  depends_on = [azurerm_key_vault_access_policy.acr]
}

# ACR with All Features
module "acr_enterprise" {
  source = "./tf-modules/modules/Azure-Container-Registries"

  acr_name                      = "acrenterprise001"
  resource_group_name           = "rg-enterprise"
  location                      = "eastus"
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false

  # CMK Encryption
  encryption_key_vault_key_id = azurerm_key_vault_key.acr.id
  encryption_identity_id      = azurerm_user_assigned_identity.acr.id

  # Diagnostic Logs
  log_analytics_workspace_id = azurerm_log_analytics_workspace.acr.id

  tags = {
    Environment = "Production"
    Security    = "Maximum"
    Compliance  = "SOC2"
    CostCenter  = "Enterprise"
  }
}
```


***

## Scenario Comparison Table

| Scenario | SKU | Admin | Public Access | CMK | Diagnostics | Use Case |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Example 1 | Basic | ✅ | ✅ | ❌ | ❌ | Dev/Test [^1] |
| Example 2 | Standard | ❌ | ✅ | ❌ | ❌ | Production (Basic) [^1] |
| Example 3 | Premium | ❌ | ❌ | ✅ | ❌ | Encrypted (CMK) [^3] |
| Example 4 | Standard | ❌ | ✅ | ❌ | ✅ | Monitoring [^3] |
| Example 5 | Premium | ❌ | ❌ | ❌ | ❌ | Private Network [^2] |
| Example 6 | Standard | ❌ | ✅ | ❌ | ✅ | Multi-Region [^2] |
| Example 7 | Standard | ❌ | ✅ | ❌ | ✅ | AKS Integration [^2] |
| Example 8 | Basic | ✅ | ✅ | ❌ | ❌ | Minimal Setup [^1] |
| Example 9 | Premium | ❌ | ❌ | ✅ | ✅ | Enterprise [^2] |


***

## Quick Reference Commands

### Login to ACR

```bash
# Using Azure CLI
az acr login --name acrprod001

# Using Docker
docker login acrprod001.azurecr.io
```


### Push Image

```bash
docker tag myapp:latest acrprod001.azurecr.io/myapp:latest
docker push acrprod001.azurecr.io/myapp:latest
```


### Pull Image from AKS

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: acrprod001.azurecr.io/myapp:latest
```

These examples cover common scenarios from simple dev setups to enterprise-grade secure ACR deployments![^1][^2][^3]
<span style="display:none">[^10][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus

[^2]: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-best-practices

[^3]: https://trendmicro.com/cloudoneconformity/knowledge-base/azure/ContainerRegistry/

[^4]: https://learn.microsoft.com/en-us/security/benchmark/azure/baselines/container-registry-security-baseline

[^5]: https://azure.microsoft.com/en-us/pricing/details/container-registry/

[^6]: https://tutorialsdojo.com/azure-container-registry/

[^7]: https://stevelasker.blog/2017/07/25/new-azure-container-registry-skus/

[^8]: https://docs.azure.cn/en-us/azure-stack/operator/container-registries-overview?view=azs-2501

[^9]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry

[^10]: https://www.reddit.com/r/AZURE/comments/p1qwvl/im_confused_by_the_azure_container_registry/

