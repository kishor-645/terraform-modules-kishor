output "app_gateway_id" {
  value = azurerm_application_gateway.appgw.id
}

output "app_gateway_frontend_ip" {
  value = azurerm_application_gateway.appgw.frontend_ip_configuration[0].private_ip_address
}
