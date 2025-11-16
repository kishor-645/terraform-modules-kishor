# Create DDoS Protection Plan if any VNET requires it
resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  count               = anytrue([for v in var.vnets : v.enable_ddos_protection]) ? 1 : 0
  name                = "${var.resource_group_name}-ddos-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  for_each            = var.vnets
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = each.value.address_space

  # --- DDoS Protection Configuration ---
  # This block is conditionally added only when enable_ddos_protection is true.
  dynamic "ddos_protection_plan" {
    for_each = each.value.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.ddos_plan[0].id
      enable = true
    }
  }

  dynamic "subnet" {
    for_each = each.value.subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
    }
  }
}