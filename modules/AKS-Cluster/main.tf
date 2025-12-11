# 1. Main Cluster Resource (Single)
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  node_resource_group = var.node_resource_group
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled           = var.private_cluster_enabled
  role_based_access_control_enabled = var.rbac_enabled
  azure_policy_enabled              = var.azure_policy_enabled

  # Connect to DES if ID is provided (For CMK)
  disk_encryption_set_id = var.disk_encryption_set_id

  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    zones               = var.default_node_pool.zones
    node_count          = var.default_node_pool.node_count
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    min_count           = var.default_node_pool.min_count
    max_count           = var.default_node_pool.max_count
    pod_limit           = var.default_node_pool.pod_limit
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type         = var.identity_id != null ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_id != null ? [var.identity_id] : []
  }

  network_profile {
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy
    load_balancer_sku = var.network_profile.load_balancer_sku
    outbound_type     = var.network_profile.outbound_type
    dns_service_ip    = var.network_profile.dns_service_ip
    service_cidr      = var.network_profile.service_cidr
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count # Handled by autoscaler
    ]
  }
}

# 2. Additional Node Pools (Multiple supported via map)
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.key
  vm_size               = each.value.vm_size
  mode                  = "User"
  
  # Network
  vnet_subnet_id = var.vnet_subnet_id # Use same subnet as cluster by default
  zones          = each.value.zones

  # Scaling
  enable_auto_scaling   = each.value.enable_auto_scaling
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  pod_limit             = each.value.pod_limit

  node_taints = each.value.node_taints
  node_labels = each.value.node_labels
  tags        = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# 3. RBAC: Auto-assign Network Contributor on the Subnet
resource "azurerm_role_assignment" "subnet_contributor" {
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.identity_id != null ? var.identity_principal_id : azurerm_kubernetes_cluster.this.identity[0].principal_id
}