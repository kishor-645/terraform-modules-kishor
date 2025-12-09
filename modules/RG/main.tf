# Create multiple resource groups from the map input
resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.key
  location = each.value.location
  tags     = merge(each.value.tags, var.common_tags)
}

# Legacy single-RG support (backward compatibility)
resource "azurerm_resource_group" "RG" {
  count = (var.resource_group_name != "" && var.location != "") ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}
