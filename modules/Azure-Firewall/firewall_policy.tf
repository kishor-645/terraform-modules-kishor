resource "azurerm_firewall_policy" "policy" {
  name                = var.firewall_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_sku_tier

  # --- DNS Configuration ---
  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }

  # --- Threat Intelligence ---
  threat_intelligence_mode = var.threat_intelligence_mode

  dynamic "threat_intelligence_allowlist" {
    # Create block only if enabled and list is not empty
    for_each = var.threat_intelligence_allowlist_enabled ? [1] : []
    content {
      ip_addresses = var.threat_intelligence_allowlist_ips
      fqdns        = var.threat_intelligence_allowlist_fqdns
    }
  }

  # --- TLS Inspection (Premium Only) ---
  # We check if enabled AND if SKU is Premium
  dynamic "tls_certificate" {
    for_each = var.tls_inspection_enabled && var.firewall_sku_tier == "Premium" ? [1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  # --- Identity (Required for TLS / Premium) ---
  dynamic "identity" {
    for_each = var.tls_inspection_enabled && var.firewall_sku_tier == "Premium" && length(var.identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  # --- IDPS (Premium Only) ---
  dynamic "intrusion_detection" {
    for_each = var.idps_mode != "Off" && var.firewall_sku_tier == "Premium" ? [1] : []
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

  # SNAT Private Ranges (Applicable to all SKUs)
  private_ip_ranges = length(var.private_ip_ranges) > 0 ? var.private_ip_ranges : null
}