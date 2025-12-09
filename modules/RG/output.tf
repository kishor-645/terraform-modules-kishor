output "resource_groups" {
  description = "Map of all created resource groups with their ids and names"
  value = {
    for k, v in azurerm_resource_group.this : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

# Legacy output (backward compatibility)
output "RG_name" {
  description = "(Deprecated) Use `resource_groups` output instead"
  value       = try(azurerm_resource_group.RG[0].name, "")
}

output "RG_id" {
  description = "(Deprecated) Use `resource_groups` output instead"
  value       = try(azurerm_resource_group.RG[0].id, "")
}