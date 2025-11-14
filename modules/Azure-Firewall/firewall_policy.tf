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
    for_each = var.threat_intelligence_allowlist_enabled ? [1] : []
    content {
      ip_addresses = var.threat_intelligence_allowlist_ips
      fqdns        = var.threat_intelligence_allowlist_fqdns
    }
  }

  # TLS Inspection Configuration (Premium SKU only)
  dynamic "tls_certificate" {
    for_each = var.tls_inspection_enabled ? [1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  # IDPS Configuration (Premium SKU only)
  dynamic "intrusion_detection" {
    for_each = var.idps_mode != "Off" ? [1] : []
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
    for_each = var.tls_inspection_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  # Private IP Ranges for SNAT
  private_ip_ranges = var.private_ip_ranges
}