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
