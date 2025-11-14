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
