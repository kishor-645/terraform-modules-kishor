resource "azurerm_cdn_frontdoor_profile" "AFD_profile" {
  name                = var.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
}
