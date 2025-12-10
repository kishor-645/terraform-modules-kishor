variable "aks_clusters" {
  description = "Map of AKS Clusters to create."
  type = map(object({
    resource_group_name = optional(string, null)
    location            = optional(string, null)

    kubernetes_version      = optional(string, "1.29")
    dns_prefix              = string
    sku_tier                = optional(string, "Free") # Use 'Free' for Dev, 'Standard' for Prod
    private_cluster_enabled = optional(bool, false)
    
    # CRITICAL: Add this line to allow defining the secondary RG
    node_resource_group     = optional(string, null) 

    # Network
    network_plugin          = optional(string, "azure")
    network_policy          = optional(string, "azure")
    vnet_subnet_id          = string 
    service_cidr            = optional(string, "10.0.0.0/16")
    dns_service_ip          = optional(string, "10.0.0.10")
    
    # Default Node Pool
    default_node_pool = object({
      name                 = string
      vm_size              = optional(string, "Standard_B4ms") # B-series for Dev
      node_count           = optional(number, 1)
      auto_scaling_enabled = optional(bool, false)
      min_count            = optional(number, 1)
      max_count            = optional(number, 3)
      zones                = optional(list(string), null) # Null = No specific zone
    })

    # Identity
    identity_type             = optional(string, "SystemAssigned")
    user_assigned_identity_id = optional(string, null)

    # CMK & Tags
    cmk_enabled          = optional(bool, false)
    cmk_key_vault_key_id = optional(string, null)
    des_identity_id      = optional(string, null)
  }))
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    cluster_name         = string
    name                 = string
    vm_size              = string
    mode                 = optional(string, "User")
    os_type              = optional(string, "Linux")
    zones                = optional(list(string), null)
    vnet_subnet_id       = optional(string, null)
    auto_scaling_enabled = optional(bool, false)
    node_count           = optional(number, 1)
    min_count            = optional(number, 1)
    max_count            = optional(number, 3)
    node_taints          = optional(list(string), [])
    node_labels          = optional(map(string), {})
  }))
  default = {}
}