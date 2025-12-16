resource "azurerm_private_dns_zone" "this" {
  for_each            = toset(var.dns_zone_names)
  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
    for pair in setproduct(toset(var.dns_zone_names), keys(var.vnet_ids_to_link)) :
    "${pair[0]}-${pair[1]}" => {
      zone_name = pair[0]
      vnet_key  = pair[1]
      vnet_id   = var.vnet_ids_to_link[pair[1]]
    }
  }

  name                  = "link-${each.value.vnet_key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_name].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false # Usually false for spoke links, true only for Hub
  tags                  = var.tags
}