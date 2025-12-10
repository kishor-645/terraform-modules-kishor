output "aks_clusters" {
  description = "Map of created AKS clusters with details."
  value = {
    for k, v in azurerm_kubernetes_cluster.this : k => {
      id                  = v.id
      name                = v.name
      fqdn                = v.fqdn
      node_resource_group = v.node_resource_group
      kubelet_identity    = v.kubelet_identity[0].object_id
      principal_id        = v.identity[0].principal_id
    }
  }
}

output "kube_configs" {
  description = "Map of kube configs (sensitive)."
  value       = { for k, v in azurerm_kubernetes_cluster.this : k => v.kube_config_raw }
  sensitive   = true
}