AKS Private Cluster Module Guide

Purpose
- Create one or more AKS private clusters with opinionated defaults for networking and security.
- Support node pools, private API server, managed identities, and integration with existing VNet/subnets.

When to use
- You need a private AKS cluster with no public API endpoint.
- You want a repeatable module that configures node pools, networkPlugin, and RBAC defaults.

Inputs (high level)
- `resource_group_name` (string) - module-level RG where AKS cluster will be created.
- `location` (string) - Azure region.
- `aks_clusters` (map(object)) - map of cluster definitions. Each cluster can include:
  - `name` (string)
  - `kubernetes_version` (optional string)
  - `node_pools` (optional map(object))
  - `vnet_subnet_id` (string) - required for private cluster nodes
  - `private_cluster_enabled` (bool) - default true
  - `enable_managed_identity` (bool)
- `common_tags` (map)

Outputs
- `aks_clusters` - map of cluster objects with `id`, `name`, `kube_admin_config` (or kubeconfig output), and `agent_pool_ids`.

Basic example (single private cluster)
```hcl
module "aks_private" {
  source = "../../modules/AKS-Private-Cluster"

  resource_group_name = "rg-prod"
  location            = "uksouth"

  aks_clusters = {
    "aks-prod" = {
      name                  = "aks-prod"
      kubernetes_version    = "1.24.6"
      vnet_subnet_id        = var.subnet_id
      private_cluster_enabled = true
      node_pools = {
        system = { vm_size = "Standard_D4s_v3", node_count = 3 }
      }
    }
  }

  common_tags = { environment = "prod" }
}
```

Advanced example (multiple clusters, AAD integration, monitoring)
```hcl
module "aks_multi" {
  source = "../../modules/AKS-Private-Cluster"
  resource_group_name = "rg-prod"
  location = "uksouth"
  aks_clusters = {
    "aks-stage" = { name = "aks-stage", vnet_subnet_id = var.subnet_stage }
    "aks-prod"  = { name = "aks-prod", vnet_subnet_id = var.subnet_prod }
  }
  enable_azure_active_directory = true
  enable_monitoring = true
}
```

Notes & best practices
- Provide `vnet_subnet_id` to place AKS nodes in your subnet and control network ACLs.
- Use tfvars for environment-specific `resource_group_name` and `location`.
- Keep cluster-count small per module call; module is designed to be scalable by passing multiple entries in `aks_clusters`.

Migration
- If you previously used per-cluster standalone resources, migrate to the `aks_clusters` map. Provide one entry for single clusters.

Support / troubleshooting
- Check `kube_admin_config` output to access cluster.
- If nodes fail provisioning, verify `vnet_subnet_id` has enough IPs and correct NSG rules.
