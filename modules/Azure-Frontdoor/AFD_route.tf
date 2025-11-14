resource "azurerm_cdn_frontdoor_route" "AFD_route" {
  name                          = var.route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.AFD_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.AFD_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.AFD_origin.id]
  enabled                       = var.route_enabled

  supported_protocols    = var.supported_protocols
  patterns_to_match      = var.patterns_to_match
  forwarding_protocol    = var.forwarding_protocol
  link_to_default_domain = var.link_to_default_domain
  https_redirect_enabled = var.https_redirect_enabled
}
