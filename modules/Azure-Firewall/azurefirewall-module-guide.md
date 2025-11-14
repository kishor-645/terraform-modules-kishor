## Updated Azure Firewall Module with Advanced Features

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

  # DNS Configuration
  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }

  # Threat Intelligence Configuration
  threat_intelligence_mode = var.threat_intelligence_mode

  dynamic "threat_intelligence_allowlist" {
    for_each = var.threat_intelligence_allowlist_enabled ? [^1] : []
    content {
      ip_addresses = var.threat_intelligence_allowlist_ips
      fqdns        = var.threat_intelligence_allowlist_fqdns
    }
  }

  # TLS Inspection Configuration (Premium SKU only)
  dynamic "tls_certificate" {
    for_each = var.tls_inspection_enabled ? [^1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  # IDPS Configuration (Premium SKU only)
  dynamic "intrusion_detection" {
    for_each = var.idps_mode != "Off" ? [^1] : []
    content {
      mode           = var.idps_mode
      private_ranges = var.idps_private_ranges

      dynamic "signature_overrides" {
        for_each = var.idps_signature_overrides
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state
        }
      }

      dynamic "traffic_bypass" {
        for_each = var.idps_traffic_bypass
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          description           = traffic_bypass.value.description
          destination_addresses = traffic_bypass.value.destination_addresses
          destination_ip_groups = traffic_bypass.value.destination_ip_groups
          destination_ports     = traffic_bypass.value.destination_ports
          source_addresses      = traffic_bypass.value.source_addresses
          source_ip_groups      = traffic_bypass.value.source_ip_groups
        }
      }
    }
  }

  # Identity for TLS Inspection (Premium SKU only)
  dynamic "identity" {
    for_each = var.tls_inspection_enabled ? [^1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  # Private IP Ranges for SNAT
  private_ip_ranges = var.private_ip_ranges
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
        terminate_tls     = rule.value.terminate_tls
        web_categories    = rule.value.web_categories

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
        destination_fqdns     = rule.value.destination_fqdns
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

variable "private_ip_ranges" {
  description = "List of private IP ranges for SNAT"
  type        = list(string)
  default     = []
}

# DNS Configuration
variable "dns_proxy_enabled" {
  description = "Enable DNS proxy"
  type        = bool
  default     = true
}

variable "dns_servers" {
  description = "List of custom DNS servers (empty for Azure default)"
  type        = list(string)
  default     = []
}

# Threat Intelligence Configuration
variable "threat_intelligence_mode" {
  description = "Threat intelligence mode (Alert, Deny, Off)"
  type        = string
  default     = "Alert"
}

variable "threat_intelligence_allowlist_enabled" {
  description = "Enable threat intelligence allowlist"
  type        = bool
  default     = false
}

variable "threat_intelligence_allowlist_ips" {
  description = "List of IP addresses to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

variable "threat_intelligence_allowlist_fqdns" {
  description = "List of FQDNs to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

# TLS Inspection Configuration (Premium SKU only)
variable "tls_inspection_enabled" {
  description = "Enable TLS inspection (requires Premium SKU)"
  type        = bool
  default     = false
}

variable "tls_certificate_key_vault_secret_id" {
  description = "Key Vault secret ID for TLS certificate"
  type        = string
  default     = ""
}

variable "tls_certificate_name" {
  description = "TLS certificate name"
  type        = string
  default     = "tls-cert"
}

variable "identity_ids" {
  description = "List of user assigned identity IDs for TLS inspection"
  type        = list(string)
  default     = []
}

# IDPS Configuration (Premium SKU only)
variable "idps_mode" {
  description = "IDPS mode (Alert, Deny, Off)"
  type        = string
  default     = "Off"
}

variable "idps_private_ranges" {
  description = "List of private IP ranges for IDPS"
  type        = list(string)
  default     = []
}

variable "idps_signature_overrides" {
  description = "List of IDPS signature overrides"
  type = list(object({
    id    = string
    state = string
  }))
  default = []
}

variable "idps_traffic_bypass" {
  description = "List of IDPS traffic bypass rules"
  type = list(object({
    name                  = string
    protocol              = string
    description           = string
    destination_addresses = list(string)
    destination_ip_groups = list(string)
    destination_ports     = list(string)
    source_addresses      = list(string)
    source_ip_groups      = list(string)
  }))
  default = []
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
    terminate_tls     = bool
    web_categories    = list(string)
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
    destination_fqdns     = list(string)
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
  value       = azurerm_firewall.firewall.ip_configuration[^0].private_ip_address
}

output "firewall_policy_id" {
  description = "Firewall policy ID"
  value       = azurerm_firewall_policy.policy.id
}

output "firewall_policy_name" {
  description = "Firewall policy name"
  value       = azurerm_firewall_policy.policy.name
}

output "dns_proxy_enabled" {
  description = "DNS proxy status"
  value       = var.dns_proxy_enabled
}

output "threat_intelligence_mode" {
  description = "Threat intelligence mode"
  value       = var.threat_intelligence_mode
}

output "tls_inspection_enabled" {
  description = "TLS inspection status"
  value       = var.tls_inspection_enabled
}

output "idps_mode" {
  description = "IDPS mode"
  value       = var.idps_mode
}
```


## Usage Examples

### Example 1: Standard Firewall with DNS and Threat Intelligence

```hcl
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"
  firewall_sku_tier    = "Standard"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  # DNS Configuration
  dns_proxy_enabled = true
  dns_servers       = ["168.63.129.16"]  # Azure DNS or custom DNS

  # Threat Intelligence
  threat_intelligence_mode = "Alert"  # Options: Alert, Deny, Off

  # Network Rules
  network_rules = [
    {
      name                  = "allow-web"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
      destination_fqdns     = []
    }
  ]
}
```


### Example 2: Premium Firewall with TLS Inspection and IDPS

```hcl
# User Assigned Identity for TLS Inspection
resource "azurerm_user_assigned_identity" "firewall" {
  name                = "id-firewall-tls"
  resource_group_name = "rg-firewall-prod"
  location            = "eastus"
}

# Key Vault Access Policy for Identity
resource "azurerm_key_vault_access_policy" "firewall" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.firewall.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]
}

module "azure_firewall_premium" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-premium-prod"
  firewall_policy_name = "fw-policy-premium"
  firewall_sku_tier    = "Premium"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id
  zones                = ["1", "2", "3"]

  # DNS Configuration
  dns_proxy_enabled = true
  dns_servers       = []  # Empty for Azure default

  # Threat Intelligence
  threat_intelligence_mode = "Deny"

  # TLS Inspection (Premium only)
  tls_inspection_enabled              = true
  tls_certificate_key_vault_secret_id = "${azurerm_key_vault.kv.vault_uri}secrets/firewall-cert"
  tls_certificate_name                = "fw-tls-cert"
  identity_ids                        = [azurerm_user_assigned_identity.firewall.id]

  # IDPS Configuration (Premium only)
  idps_mode          = "Alert"  # Options: Alert, Deny, Off
  idps_private_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  # Application Rules with TLS Inspection
  application_rules = [
    {
      name              = "allow-microsoft-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.microsoft.com", "*.windows.net"]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = true
      web_categories    = []
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
      destination_fqdns     = []
    }
  ]
}
```


### Example 3: Premium Firewall with IDPS Signature Overrides

```hcl
module "azure_firewall_idps" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-premium-idps"
  firewall_policy_name = "fw-policy-idps"
  firewall_sku_tier    = "Premium"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  # DNS Configuration
  dns_proxy_enabled = true

  # Threat Intelligence with Allowlist
  threat_intelligence_mode               = "Alert"
  threat_intelligence_allowlist_enabled  = true
  threat_intelligence_allowlist_ips      = ["203.0.113.0/24"]
  threat_intelligence_allowlist_fqdns    = ["trusted.example.com"]

  # IDPS with Signature Overrides
  idps_mode = "Alert"
  idps_private_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  idps_signature_overrides = [
    {
      id    = "2024897"
      state = "Alert"
    },
    {
      id    = "2024898"
      state = "Deny"
    }
  ]

  # IDPS Traffic Bypass
  idps_traffic_bypass = [
    {
      name                  = "bypass-internal-scan"
      protocol              = "TCP"
      description           = "Bypass security scanner traffic"
      destination_addresses = ["10.0.10.50"]
      destination_ip_groups = []
      destination_ports     = ["443"]
      source_addresses      = ["10.0.5.0/24"]
      source_ip_groups      = []
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-outbound"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
      destination_fqdns     = []
    }
  ]
}
```


### Example 4: Complete Setup with All Features (Premium)

```hcl
# Prerequisites
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "firewall" {
  name     = "rg-firewall-prod"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-firewall"
  resource_group_name = azurerm_resource_group.firewall.name
  location            = azurerm_resource_group.firewall.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  resource_group_name = azurerm_resource_group.firewall.name
  location            = azurerm_resource_group.firewall.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_user_assigned_identity" "firewall" {
  name                = "id-firewall"
  resource_group_name = azurerm_resource_group.firewall.name
  location            = azurerm_resource_group.firewall.location
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-firewall-tls"
  resource_group_name = azurerm_resource_group.firewall.name
  location            = azurerm_resource_group.firewall.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "firewall" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.firewall.principal_id

  secret_permissions = ["Get", "List"]
  certificate_permissions = ["Get", "List"]
}

# Azure Firewall Module with All Features
module "azure_firewall_complete" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = azurerm_resource_group.firewall.name
  location             = azurerm_resource_group.firewall.location
  firewall_name        = "fw-premium-complete"
  firewall_policy_name = "fw-policy-complete"
  firewall_sku_tier    = "Premium"
  zones                = ["1", "2", "3"]

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  private_ip_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  # DNS Configuration - Enabled
  dns_proxy_enabled = true
  dns_servers       = []

  # Threat Intelligence - Deny Mode
  threat_intelligence_mode              = "Deny"
  threat_intelligence_allowlist_enabled = true
  threat_intelligence_allowlist_ips     = ["203.0.113.50"]
  threat_intelligence_allowlist_fqdns   = ["trusted-partner.com"]

  # TLS Inspection - Enabled
  tls_inspection_enabled              = true
  tls_certificate_key_vault_secret_id = "${azurerm_key_vault.kv.vault_uri}secrets/firewall-cert"
  tls_certificate_name                = "fw-tls-cert"
  identity_ids                        = [azurerm_user_assigned_identity.firewall.id]

  # IDPS - Alert Mode
  idps_mode = "Alert"
  idps_private_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  idps_signature_overrides = [
    {
      id    = "2024897"
      state = "Alert"
    }
  ]

  # Application Rules with TLS Inspection
  application_rules = [
    {
      name              = "allow-aks-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.azmk8s.io", "mcr.microsoft.com"]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = true
      web_categories    = []
    },
    {
      name              = "allow-web-categories"
      source_addresses  = ["10.0.2.0/24"]
      destination_fqdns = []
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = false
      web_categories    = ["Business", "ComputerAndInformationSecurity"]
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-ntp-dns"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53", "123"]
      destination_fqdns     = []
    },
    {
      name                  = "allow-api-server"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["AzureCloud.EastUS"]
      destination_ports     = ["443", "9000"]
      destination_fqdns     = []
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
      translated_address  = "10.0.10.10"
      translated_port     = 22
    }
  ]
}

# Outputs
output "firewall_private_ip" {
  value = module.azure_firewall_complete.firewall_private_ip
}

output "firewall_features" {
  value = {
    dns_proxy_enabled      = module.azure_firewall_complete.dns_proxy_enabled
    threat_intelligence    = module.azure_firewall_complete.threat_intelligence_mode
    tls_inspection_enabled = module.azure_firewall_complete.tls_inspection_enabled
    idps_mode              = module.azure_firewall_complete.idps_mode
  }
}
```


## Feature Configuration Guide

### DNS Configuration[^4]

```hcl
# Enable DNS Proxy
dns_proxy_enabled = true

# Use Azure DNS (default)
dns_servers = []

# Use Custom DNS Servers
dns_servers = ["10.0.0.4", "10.0.0.5"]
```


### Threat Intelligence[^2]

```hcl
# Alert Mode - Monitor threats
threat_intelligence_mode = "Alert"

# Deny Mode - Block known threats
threat_intelligence_mode = "Deny"

# With Allowlist
threat_intelligence_allowlist_enabled = true
threat_intelligence_allowlist_ips     = ["203.0.113.0/24"]
threat_intelligence_allowlist_fqdns   = ["trusted.example.com"]
```


### TLS Inspection (Premium SKU)[^1]

```hcl
# Enable TLS Inspection
tls_inspection_enabled              = true
tls_certificate_key_vault_secret_id = "https://kv-name.vault.azure.net/secrets/cert-name"
tls_certificate_name                = "tls-cert"
identity_ids                        = [azurerm_user_assigned_identity.fw.id]

# Use in Application Rules
application_rules = [
  {
    terminate_tls = true  # Decrypt and inspect HTTPS traffic
    # ... other settings
  }
]
```


### IDPS Configuration (Premium SKU)[^3][^2]

```hcl
# Enable IDPS
idps_mode = "Alert"  # Options: Alert, Deny, Off

# Define Private IP Ranges
idps_private_ranges = [
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16"
]

# Signature Overrides
idps_signature_overrides = [
  {
    id    = "2024897"
    state = "Alert"  # Options: Alert, Deny, Off
  }
]

# Traffic Bypass
idps_traffic_bypass = [
  {
    name                  = "bypass-scanner"
    protocol              = "TCP"
    description           = "Bypass vulnerability scanner"
    source_addresses      = ["10.0.5.0/24"]
    destination_addresses = ["10.0.10.0/24"]
    destination_ports     = ["443"]
    # ... other settings
  }
]
```


## SKU Requirements

| Feature | Standard | Premium |
| :-- | :-- | :-- |
| DNS Proxy | ✅ | ✅ |
| Threat Intelligence | ✅ | ✅ |
| TLS Inspection | ❌ | ✅ |
| IDPS | ❌ | ✅ |

## Important Notes

**Premium SKU Required** for TLS Inspection and IDPS[^2][^1]
**User Assigned Identity** required for TLS inspection to access Key Vault
**Key Vault Certificate** must be in correct format for TLS inspection
**DNS Proxy** must be enabled for FQDN filtering in network rules
**Private IP Ranges** should match your internal network for IDPS
**IDPS Signature IDs** can be found in Azure Portal under Firewall Policy IDPS settings[^3]
