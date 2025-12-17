output "id" {
  description = "The Resource ID of the Route Table"
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "The Name of the Route Table"
  value       = azurerm_route_table.this.name
}