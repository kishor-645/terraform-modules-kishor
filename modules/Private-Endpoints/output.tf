output "private_endpoints" {
  value = {
    for k, v in azurerm_private_endpoint.this : k => {
      id = v.id
      ip = v.private_service_connection[0].private_ip_address
    }
  }
}