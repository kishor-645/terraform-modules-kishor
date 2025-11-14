output "afd_profile_id" {
  description = "The ID of the Azure Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.AFD_profile.id
}

output "afd_endpoint_host_name" {
  description = "The host name of the Azure Front Door endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.AFD_endpoint.host_name
}

output "afd_origin_group_id" {
  description = "The ID of the Azure Front Door origin group."
  value       = azurerm_cdn_frontdoor_origin_group.AFD_origin_group.id
}

output "afd_route_id" {
  description = "The ID of the Azure Front Door route."
  value       = azurerm_cdn_frontdoor_route.AFD_route.id
}
