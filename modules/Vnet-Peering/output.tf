output "peering_ids" {
  description = "Map of all Created Peering IDs"
  value = merge(
    { for k, v in azurerm_virtual_network_peering.direction_a_to_b : "${k}-forward" => v.id },
    { for k, v in azurerm_virtual_network_peering.direction_b_to_a : "${k}-reverse" => v.id }
  )
}