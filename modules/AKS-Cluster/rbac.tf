# Automatically assign Network Contributor to the AgentPool Subnet
# This is required for AKS to create Load Balancers and Route Tables
resource "azurerm_role_assignment" "subnet_contributor" {
  for_each = var.aks_clusters

  scope                = each.value.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = (each.value.identity_type == "UserAssigned" && each.value.user_assigned_identity_id != null) ? data.azurerm_user_assigned_identity.provided[each.key].principal_id : azurerm_kubernetes_cluster.this[each.key].identity[0].principal_id
}

# Data lookup helper
data "azurerm_user_assigned_identity" "provided" {
  for_each            = { for k, v in var.aks_clusters : k => v if v.identity_type == "UserAssigned" }
  name                = split("/", each.value.user_assigned_identity_id)[8]
  resource_group_name = split("/", each.value.user_assigned_identity_id)[4]
}