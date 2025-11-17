<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# okay now, I need Diagnostic settings separate module, with all flexibility and dynamic like i can attache it with any azure resource  like AKS, Azure firewall, ACR, etc... It should be simple and dynamic. with all the examples like how to use it.

Perfect! I'll create a simple, flexible, and reusable Diagnostic Settings module that can be attached to any Azure resource.[^1][^2][^3]

## Diagnostic Settings Module

### Directory Structure

```
tf-modules/
└── modules/
    └── Diagnostic-Settings/
        ├── diagnostic_settings.tf
        ├── variables.tf
        └── output.tf
```


***

### diagnostic_settings.tf

```hcl
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = var.diagnostic_setting_name
  target_resource_id             = var.target_resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  storage_account_id             = var.storage_account_id
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  eventhub_name                  = var.eventhub_name
  log_analytics_destination_type = var.log_analytics_destination_type

  # Dynamic enabled logs
  dynamic "enabled_log" {
    for_each = var.enabled_logs
    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  # Dynamic metrics
  dynamic "metric" {
    for_each = var.enabled_metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}
```


***

### variables.tf

```hcl
variable "diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  type        = string
}

variable "target_resource_id" {
  description = "ID of the target resource to enable diagnostics on"
  type        = string
}

# Destination Variables
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Storage Account ID for long-term retention"
  type        = string
  default     = null
}

variable "eventhub_authorization_rule_id" {
  description = "Event Hub Authorization Rule ID"
  type        = string
  default     = null
}

variable "eventhub_name" {
  description = "Event Hub Name"
  type        = string
  default     = null
}

variable "log_analytics_destination_type" {
  description = "Log Analytics destination type (Dedicated or AzureDiagnostics)"
  type        = string
  default     = null
}

# Logs Configuration
variable "enabled_logs" {
  description = "List of log categories to enable"
  type = list(object({
    category       = optional(string)
    category_group = optional(string)
  }))
  default = []
}

# Metrics Configuration
variable "enabled_metrics" {
  description = "List of metrics to enable"
  type = list(object({
    category = string
    enabled  = bool
  }))
  default = []
}
```


***

### output.tf

```hcl
output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.name
}
```


***

## Usage Examples

### Example 1: AKS with Log Analytics (Common Logs)[^1]

```hcl
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "law-monitoring"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-prod"
  resource_group_name = "rg-aks"
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

# Diagnostic Settings for AKS
module "aks_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-aks-prod"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = [
    {
      category       = "kube-apiserver"
      category_group = null
    },
    {
      category       = "kube-controller-manager"
      category_group = null
    },
    {
      category       = "kube-scheduler"
      category_group = null
    },
    {
      category       = "kube-audit"
      category_group = null
    },
    {
      category       = "cluster-autoscaler"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 2: ACR with Storage Account (Long-term Retention)[^1]

```hcl
# Storage Account for archival
resource "azurerm_storage_account" "logs" {
  name                     = "salogarchive001"
  resource_group_name      = "rg-monitoring"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# ACR
resource "azurerm_container_registry" "acr" {
  name                = "acrprod001"
  resource_group_name = "rg-acr"
  location            = "eastus"
  sku                 = "Premium"
  admin_enabled       = false
}

# Diagnostic Settings for ACR
module "acr_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name = "diag-acr-prod"
  target_resource_id      = azurerm_container_registry.acr.id
  storage_account_id      = azurerm_storage_account.logs.id

  enabled_logs = [
    {
      category       = "ContainerRegistryRepositoryEvents"
      category_group = null
    },
    {
      category       = "ContainerRegistryLoginEvents"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 3: Azure Firewall with Multiple Destinations[^3][^1]

```hcl
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "firewall" {
  name                = "law-firewall"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# Storage Account for compliance
resource "azurerm_storage_account" "firewall_logs" {
  name                     = "safirewallcompliance"
  resource_group_name      = "rg-monitoring"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Azure Firewall
resource "azurerm_firewall" "firewall" {
  name                = "fw-prod"
  resource_group_name = "rg-firewall"
  location            = "eastus"
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.policy.id

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Diagnostic Settings for Azure Firewall
module "firewall_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-firewall-prod"
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.firewall.id
  storage_account_id         = azurerm_storage_account.firewall_logs.id

  enabled_logs = [
    {
      category       = "AzureFirewallApplicationRule"
      category_group = null
    },
    {
      category       = "AzureFirewallNetworkRule"
      category_group = null
    },
    {
      category       = "AzureFirewallDnsProxy"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 4: Key Vault with Event Hub[^1]

```hcl
# Event Hub Namespace
resource "azurerm_eventhub_namespace" "monitoring" {
  name                = "ehns-monitoring"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "Standard"
  capacity            = 2
}

# Event Hub
resource "azurerm_eventhub" "logs" {
  name                = "eh-logs"
  namespace_name      = azurerm_eventhub_namespace.monitoring.name
  resource_group_name = "rg-monitoring"
  partition_count     = 2
  message_retention   = 1
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "kv-prod-001"
  resource_group_name = "rg-security"
  location            = "eastus"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

# Diagnostic Settings for Key Vault
module "keyvault_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name        = "diag-kv-prod"
  target_resource_id             = azurerm_key_vault.kv.id
  eventhub_authorization_rule_id = "${azurerm_eventhub_namespace.monitoring.id}/authorizationrules/RootManageSharedAccessKey"
  eventhub_name                  = azurerm_eventhub.logs.name

  enabled_logs = [
    {
      category       = "AuditEvent"
      category_group = null
    },
    {
      category       = "AzurePolicyEvaluationDetails"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 5: Using Category Groups (All Logs)[^4][^3]

```hcl
# Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-prod-001"
  resource_group_name = "rg-compute"
  location            = "eastus"
  size                = "Standard_D4s_v3"
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.vm.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Diagnostic Settings with Category Group
module "vm_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-vm-prod"
  target_resource_id         = azurerm_linux_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = [
    {
      category       = null
      category_group = "allLogs"
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 6: Application Gateway[^1]

```hcl
# Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-prod"
  resource_group_name = "rg-network"
  location            = "eastus"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }
}

# Diagnostic Settings for Application Gateway
module "appgw_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-appgw-prod"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = [
    {
      category       = "ApplicationGatewayAccessLog"
      category_group = null
    },
    {
      category       = "ApplicationGatewayPerformanceLog"
      category_group = null
    },
    {
      category       = "ApplicationGatewayFirewallLog"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 7: Storage Account (Multiple Resources)[^5]

```hcl
# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "saprod001"
  resource_group_name      = "rg-storage"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Diagnostic Settings for Storage Account (Account level)
module "storage_account_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-storage-account"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = []

  enabled_metrics = [
    {
      category = "Transaction"
      enabled  = true
    }
  ]
}

# Diagnostic Settings for Blob Service
module "storage_blob_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-storage-blob"
  target_resource_id         = "${azurerm_storage_account.storage.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = [
    {
      category       = "StorageRead"
      category_group = null
    },
    {
      category       = "StorageWrite"
      category_group = null
    },
    {
      category       = "StorageDelete"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "Transaction"
      enabled  = true
    }
  ]
}
```


***

### Example 8: PostgreSQL Flexible Server

```hcl
# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "psql-prod-001"
  resource_group_name = "rg-database"
  location            = "eastus"
  version             = "14"
  administrator_login = "psqladmin"
  administrator_password = random_password.postgres.result

  storage_mb = 32768
  sku_name   = "GP_Standard_D4s_v3"
}

# Diagnostic Settings for PostgreSQL
module "postgres_diagnostics" {
  source = "./tf-modules/modules/Diagnostic-Settings"

  diagnostic_setting_name    = "diag-postgres-prod"
  target_resource_id         = azurerm_postgresql_flexible_server.postgres.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_logs = [
    {
      category       = "PostgreSQLLogs"
      category_group = null
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}
```


***

### Example 9: Complete Multi-Resource Setup

```hcl
# Shared Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "central" {
  name                = "law-central-monitoring"
  resource_group_name = "rg-monitoring"
  location            = "eastus"
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# AKS Diagnostics
module "aks_diag" {
  source                     = "./tf-modules/modules/Diagnostic-Settings"
  diagnostic_setting_name    = "diag-aks"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_logs = [
    { category = "kube-apiserver", category_group = null },
    { category = "kube-audit", category_group = null }
  ]

  enabled_metrics = [{ category = "AllMetrics", enabled = true }]
}

# ACR Diagnostics
module "acr_diag" {
  source                     = "./tf-modules/modules/Diagnostic-Settings"
  diagnostic_setting_name    = "diag-acr"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_logs = [
    { category = "ContainerRegistryLoginEvents", category_group = null }
  ]

  enabled_metrics = [{ category = "AllMetrics", enabled = true }]
}

# Firewall Diagnostics
module "firewall_diag" {
  source                     = "./tf-modules/modules/Diagnostic-Settings"
  diagnostic_setting_name    = "diag-firewall"
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_logs = [
    { category = "AzureFirewallApplicationRule", category_group = null },
    { category = "AzureFirewallNetworkRule", category_group = null }
  ]

  enabled_metrics = [{ category = "AllMetrics", enabled = true }]
}

# Key Vault Diagnostics
module "keyvault_diag" {
  source                     = "./tf-modules/modules/Diagnostic-Settings"
  diagnostic_setting_name    = "diag-keyvault"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_logs = [
    { category = "AuditEvent", category_group = null }
  ]

  enabled_metrics = [{ category = "AllMetrics", enabled = true }]
}
```


***

## Common Log Categories Reference

### AKS[^5]

- `kube-apiserver`
- `kube-controller-manager`
- `kube-scheduler`
- `kube-audit`
- `cluster-autoscaler`
- `guard`


### ACR[^1]

- `ContainerRegistryRepositoryEvents`
- `ContainerRegistryLoginEvents`


### Azure Firewall

- `AzureFirewallApplicationRule`
- `AzureFirewallNetworkRule`
- `AzureFirewallDnsProxy`


### Key Vault

- `AuditEvent`
- `AzurePolicyEvaluationDetails`


### Application Gateway

- `ApplicationGatewayAccessLog`
- `ApplicationGatewayPerformanceLog`
- `ApplicationGatewayFirewallLog`


### Storage Account

- `StorageRead`
- `StorageWrite`
- `StorageDelete`

***

## Destination Comparison

| Destination | Use Case | Retention | Cost |
| :-- | :-- | :-- | :-- |
| **Log Analytics** | Query, alerting, dashboards | 30-730 days | Per GB ingested [^1] |
| **Storage Account** | Long-term compliance | Years | Low cost archive [^1] |
| **Event Hub** | Stream to SIEM/external | Real-time | Per message [^3] |

This module is simple, flexible, and can be attached to any Azure resource with diagnostic capabilities![^2][^3][^1]
<span style="display:none">[^10][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://www.techielass.com/enable-azure-monitor-diagnostic-settings-terraform/

[^2]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting

[^3]: https://learn.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings

[^4]: https://discuss.hashicorp.com/t/azure-diagnostic-settings-category-group-argument-is-not-available/40965

[^5]: https://stackoverflow.com/questions/76943384/create-diagnostic-setting-with-terraform-to-send-specific-log-categories-to-log

[^6]: https://shisho.dev/dojo/providers/azurerm/Monitor/azurerm-monitor-diagnostic-setting/

[^7]: https://discuss.hashicorp.com/t/how-do-i-configure-diagnostics-settings-for-activity-monitor/68652

[^8]: https://stackoverflow.com/questions/77944689/azurerm-diagnostic-setting

[^9]: https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings

[^10]: https://github.com/claranet/terraform-azurerm-diagnostic-settings

