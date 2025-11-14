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