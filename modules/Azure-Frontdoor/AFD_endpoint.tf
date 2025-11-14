resource "azurerm_cdn_frontdoor_endpoint" "AFD_endpoint" {
  name                     = var.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.AFD_profile.id

#   tags = var.tags
}
