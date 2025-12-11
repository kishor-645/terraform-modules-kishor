resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.aks_clusters

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.kubernetes_version
  sku_tier            = each.value.sku_tier

  node_resource_group = each.value.node_resource_group

  # Link the Disk Encryption Set if CMK is enabled
  disk_encryption_set_id = try(each.value.cmk_enabled, false) ? azurerm_disk_encryption_set.des[each.key].id : null

  default_node_pool {
    name       = each.value.default_node_pool.name
    vm_size    = each.value.default_node_pool.vm_size
    vnet_subnet_id       = each.value.vnet_subnet_id
    zones      = each.value.default_node_pool.zones
    node_count = each.value.default_node_pool.node_count
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_type == "UserAssigned" && each.value.user_assigned_identity_id != null ? [each.value.user_assigned_identity_id] : []
  }

  network_profile {
    network_plugin    = each.value.network_plugin
    network_policy    = each.value.network_policy
    load_balancer_sku = each.value.load_balancer_sku != null ? each.value.load_balancer_sku : "Standard"
    outbound_type     = each.value.outbound_type != null ? each.value.outbound_type : "LoadBalancer"
    dns_service_ip    = each.value.dns_service_ip
    service_cidr      = each.value.service_cidr
  }

  private_cluster_enabled           = each.value.private_cluster_enabled
  role_based_access_control_enabled = true
  azure_policy_enabled              = true

  tags = merge(var.common_tags, try(each.value.tags, {}))

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count # Ignored because Autoscaler manages this
    ]
  }
}

# Separate User Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[each.value.cluster_name].id
  name                  = each.value.name
  vm_size               = each.value.vm_size
  mode                  = each.value.mode
  os_type               = each.value.os_type
  zones                 = each.value.zones
  
  vnet_subnet_id        = try(each.value.vnet_subnet_id, azurerm_kubernetes_cluster.this[each.value.cluster_name].default_node_pool[0].vnet_subnet_id)

  auto_scaling_enabled  = each.value.auto_scaling_enabled
  node_count            = each.value.auto_scaling_enabled ? null : each.value.node_count
  min_count             = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count             = each.value.auto_scaling_enabled ? each.value.max_count : null

  node_taints           = each.value.node_taints
  node_labels           = each.value.node_labels
  tags                  = var.common_tags

  lifecycle {
    ignore_changes = [node_count]
  }
}