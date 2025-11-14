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
