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