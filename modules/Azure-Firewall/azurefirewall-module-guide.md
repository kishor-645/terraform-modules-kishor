<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# see regarding the azure firewall module creation you did great job but i need it in simple way also in separate separate file like main.tf contains azure firewall creation, application rule, dnat rule, network rule, firewall policy.

like this recreate me but it should be simple and reusable terraform module.

Based on your repository structure and preference for simplicity, I'll recreate the Azure Firewall module in a simple, organized way with separate files for each component.

## Simplified Azure Firewall Module

### Directory Structure

```
tf-modules/
└── modules/
    └── Azure-Firewall/
        ├── firewall.tf
        ├── firewall_policy.tf
        ├── application_rules.tf
        ├── network_rules.tf
        ├── nat_rules.tf
        ├── variables.tf
        └── output.tf
```


### firewall_policy.tf

```hcl
resource "azurerm_firewall_policy" "policy" {
  name                = var.firewall_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_sku_tier

  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }

  threat_intelligence_mode = var.threat_intelligence_mode
}
```


### firewall.tf

```hcl
resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.policy.id
  zones               = var.zones

  ip_configuration {
    name                 = var.ip_configuration_name
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_address_id
  }
}
```


### application_rules.tf

```hcl
resource "azurerm_firewall_policy_rule_collection_group" "app_rules" {
  count              = length(var.application_rules) > 0 ? 1 : 0
  name               = "app-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = var.application_rule_priority

  application_rule_collection {
    name     = "app-rule-collection"
    priority = var.application_rule_priority
    action   = var.application_rule_action

    dynamic "rule" {
      for_each = var.application_rules
      content {
        name = rule.value.name

        source_addresses  = rule.value.source_addresses
        destination_fqdns = rule.value.destination_fqdns

        protocols {
          type = rule.value.protocol_type
          port = rule.value.protocol_port
        }
      }
    }
  }
}
```


### network_rules.tf

```hcl
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  count              = length(var.network_rules) > 0 ? 1 : 0
  name               = "network-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = var.network_rule_priority

  network_rule_collection {
    name     = "network-rule-collection"
    priority = var.network_rule_priority
    action   = var.network_rule_action

    dynamic "rule" {
      for_each = var.network_rules
      content {
        name                  = rule.value.name
        protocols             = rule.value.protocols
        source_addresses      = rule.value.source_addresses
        destination_addresses = rule.value.destination_addresses
        destination_ports     = rule.value.destination_ports
      }
    }
  }
}
```


### nat_rules.tf

```hcl
resource "azurerm_firewall_policy_rule_collection_group" "nat_rules" {
  count              = length(var.nat_rules) > 0 ? 1 : 0
  name               = "nat-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = var.nat_rule_priority

  nat_rule_collection {
    name     = "nat-rule-collection"
    priority = var.nat_rule_priority
    action   = "Dnat"

    dynamic "rule" {
      for_each = var.nat_rules
      content {
        name                = rule.value.name
        protocols           = rule.value.protocols
        source_addresses    = rule.value.source_addresses
        destination_address = rule.value.destination_address
        destination_ports   = rule.value.destination_ports
        translated_address  = rule.value.translated_address
        translated_port     = rule.value.translated_port
      }
    }
  }
}
```


### variables.tf

```hcl
# General Variables
variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

# Firewall Policy Variables
variable "firewall_policy_name" {
  description = "Firewall policy name"
  type        = string
}

variable "firewall_sku_tier" {
  description = "Firewall SKU tier (Standard, Premium, Basic)"
  type        = string
  default     = "Standard"
}

variable "dns_proxy_enabled" {
  description = "Enable DNS proxy"
  type        = bool
  default     = true
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = []
}

variable "threat_intelligence_mode" {
  description = "Threat intelligence mode (Alert, Deny, Off)"
  type        = string
  default     = "Alert"
}

# Firewall Variables
variable "firewall_name" {
  description = "Azure Firewall name"
  type        = string
}

variable "firewall_sku_name" {
  description = "Firewall SKU name (AZFW_VNet, AZFW_Hub)"
  type        = string
  default     = "AZFW_VNet"
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
  default     = []
}

variable "ip_configuration_name" {
  description = "IP configuration name"
  type        = string
  default     = "fw-ipconfig"
}

variable "subnet_id" {
  description = "AzureFirewallSubnet ID"
  type        = string
}

variable "public_ip_address_id" {
  description = "Public IP address ID"
  type        = string
}

# Application Rules Variables
variable "application_rules" {
  description = "List of application rules"
  type = list(object({
    name              = string
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocol_type     = string
    protocol_port     = number
  }))
  default = []
}

variable "application_rule_priority" {
  description = "Application rule priority"
  type        = number
  default     = 100
}

variable "application_rule_action" {
  description = "Application rule action (Allow, Deny)"
  type        = string
  default     = "Allow"
}

# Network Rules Variables
variable "network_rules" {
  description = "List of network rules"
  type = list(object({
    name                  = string
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  default = []
}

variable "network_rule_priority" {
  description = "Network rule priority"
  type        = number
  default     = 200
}

variable "network_rule_action" {
  description = "Network rule action (Allow, Deny)"
  type        = string
  default     = "Allow"
}

# NAT Rules Variables
variable "nat_rules" {
  description = "List of NAT rules"
  type = list(object({
    name                = string
    protocols           = list(string)
    source_addresses    = list(string)
    destination_address = string
    destination_ports   = list(string)
    translated_address  = string
    translated_port     = number
  }))
  default = []
}

variable "nat_rule_priority" {
  description = "NAT rule priority"
  type        = number
  default     = 300
}
```


### output.tf

```hcl
output "firewall_id" {
  description = "Firewall ID"
  value       = azurerm_firewall.firewall.id
}

output "firewall_name" {
  description = "Firewall name"
  value       = azurerm_firewall.firewall.name
}

output "firewall_private_ip" {
  description = "Firewall private IP address"
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "Firewall policy ID"
  value       = azurerm_firewall_policy.policy.id
}

output "firewall_policy_name" {
  description = "Firewall policy name"
  value       = azurerm_firewall_policy.policy.name
}
```


## Usage Examples

### Example 1: Basic Firewall with Network Rules (AKS Outbound)

```hcl
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  # Network Rules for AKS
  network_rules = [
    {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    },
    {
      name                  = "allow-dns"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    },
    {
      name                  = "allow-https"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
    }
  ]
}
```


### Example 2: Firewall with Application Rules (AKS Required FQDNs)

```hcl
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-aks-prod"
  firewall_policy_name = "fw-policy-aks"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  # Application Rules for AKS
  application_rules = [
    {
      name              = "allow-aks-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.azmk8s.io", "*.blob.core.windows.net"]
      protocol_type     = "Https"
      protocol_port     = 443
    },
    {
      name              = "allow-mcr"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["mcr.microsoft.com", "*.data.mcr.microsoft.com"]
      protocol_type     = "Https"
      protocol_port     = 443
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-api-server"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["AzureCloud.EastUS"]
      destination_ports     = ["443", "9000"]
    }
  ]
}
```


### Example 3: Firewall with NAT Rules (Jumpbox Access)

```hcl
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  # NAT Rules for inbound access
  nat_rules = [
    {
      name                = "ssh-jumpbox"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = "20.10.10.10"  # Firewall public IP
      destination_ports   = ["2222"]
      translated_address  = "10.0.1.10"    # Jumpbox private IP
      translated_port     = 22
    },
    {
      name                = "rdp-jumpbox"
      protocols           = ["TCP"]
      source_addresses    = ["203.0.113.0/24"]  # Your office IP
      destination_address = "20.10.10.10"
      destination_ports   = ["3389"]
      translated_address  = "10.0.1.11"
      translated_port     = 3389
    }
  ]
}
```


### Example 4: Complete Setup with All Rule Types

```hcl
# Public IP for Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  resource_group_name = "rg-network"
  location            = "eastus"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Firewall Subnet
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "rg-network"
  virtual_network_name = "vnet-prod"
  address_prefixes     = ["10.0.1.0/26"]
}

# Azure Firewall Module
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"
  firewall_sku_tier    = "Standard"
  zones                = ["1", "2", "3"]

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  dns_proxy_enabled = true
  dns_servers       = ["168.63.129.16"]

  # Application Rules
  application_rules = [
    {
      name              = "allow-microsoft-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.microsoft.com", "*.windows.net"]
      protocol_type     = "Https"
      protocol_port     = 443
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-web"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }
  ]

  # NAT Rules
  nat_rules = [
    {
      name                = "ssh-jumpbox"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["2222"]
      translated_address  = "10.0.1.10"
      translated_port     = 22
    }
  ]
}

# Outputs
output "firewall_private_ip" {
  value = module.azure_firewall.firewall_private_ip
}
```


### Example 5: Multiple Rule Collections (Using Multiple Module Calls)

If you need multiple rule collection groups with different priorities, you can create separate instances:

```hcl
# High Priority Application Rules
module "azure_firewall_app_rules" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  application_rule_priority = 100
  
  application_rules = [
    {
      name              = "allow-critical-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.azmk8s.io"]
      protocol_type     = "Https"
      protocol_port     = 443
    }
  ]
}
```


## Common Rule Examples Reference

### AKS Required Rules

```hcl
# Application Rules
application_rules = [
  {
    name              = "aks-required-fqdns"
    source_addresses  = ["10.0.0.0/16"]
    destination_fqdns = [
      "*.azmk8s.io",
      "*.blob.core.windows.net",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net"
    ]
    protocol_type = "Https"
    protocol_port = 443
  }
]

# Network Rules
network_rules = [
  {
    name                  = "aks-api-server"
    protocols             = ["TCP"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["AzureCloud"]
    destination_ports     = ["443", "9000"]
  },
  {
    name                  = "ntp"
    protocols             = ["UDP"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["*"]
    destination_ports     = ["123"]
  }
]
```


### Private Endpoint Access

```hcl
application_rules = [
  {
    name              = "allow-private-endpoints"
    source_addresses  = ["10.0.0.0/16"]
    destination_fqdns = [
      "*.privatelink.blob.core.windows.net",
      "*.privatelink.vaultcore.azure.net",
      "*.privatelink.azurecr.io"
    ]
    protocol_type = "Https"
    protocol_port = 443
  }
]
```


## Module Features

✅ **Simple structure** - Each rule type in its own file
✅ **Easy to understand** - Clear variable names
✅ **Reusable** - Works like your other modules
✅ **Dynamic** - All values are variables
✅ **Optional rules** - Use only what you need
✅ **Clean outputs** - Essential information only

This simplified module follows your repository's pattern and makes it easy to manage Azure Firewall with separate files for each component!

