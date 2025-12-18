output "id" { value = azurerm_kubernetes_cluster.this.id }
output "name" { value = azurerm_kubernetes_cluster.this.name }
output "kubelet_identity" { value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id }

output "oidc_issuer_url" {
  description = "The OIDC Issuer URL used for Workload Identity"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}