terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

# ----------------------------------------------------------------------
# Direction 1: From Source (A) -> Destination (B)
# ----------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "direction_a_to_b" {
  for_each = var.peerings

  name                      = "peer-${each.value.vnet_a_name}-to-${each.value.vnet_b_name}"
  resource_group_name       = each.value.vnet_a_rg
  virtual_network_name      = each.value.vnet_a_name
  remote_virtual_network_id = each.value.vnet_b_id

  # Traffic Settings
  allow_virtual_network_access = try(each.value.allow_vnet_access, true)
  allow_forwarded_traffic      = try(each.value.allow_forwarded_traffic, true)
  
  # Gateway Settings (Specific to A -> B)
  allow_gateway_transit        = try(each.value.vnet_a_allow_gateway_transit, false)
  use_remote_gateways          = try(each.value.vnet_a_use_remote_gateways, false)
}

# ----------------------------------------------------------------------
# Direction 2: From Destination (B) -> Source (A)
# ----------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "direction_b_to_a" {
  for_each = var.peerings

  name                      = "peer-${each.value.vnet_b_name}-to-${each.value.vnet_a_name}"
  resource_group_name       = each.value.vnet_b_rg
  virtual_network_name      = each.value.vnet_b_name
  remote_virtual_network_id = each.value.vnet_a_id

  # Traffic Settings
  allow_virtual_network_access = try(each.value.allow_vnet_access, true)
  allow_forwarded_traffic      = try(each.value.allow_forwarded_traffic, true)

  # Gateway Settings (Specific to B -> A)
  allow_gateway_transit        = try(each.value.vnet_b_allow_gateway_transit, false)
  use_remote_gateways          = try(each.value.vnet_b_use_remote_gateways, false)
}