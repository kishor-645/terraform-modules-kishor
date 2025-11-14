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
