# Core Settings
variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "node_resource_group" { type = string }
variable "location" { type = string }
variable "dns_prefix" { type = string }
variable "kubernetes_version" { default = "1.29" }
variable "sku_tier" { default = "Standard" }
variable "tags" { type = map(string) }

# Toggle Features
variable "private_cluster_enabled" { 
  type    = bool
  default = false
}

variable "rbac_enabled" { 
  type    = bool
  default = false
}

variable "azure_policy_enabled" { 
  type    = bool
  default = false
}

# Identity
variable "identity_id" { 
  description = "User Assigned Identity ID. Null = SystemAssigned"
  type        = string
  default     = null 
}
variable "identity_principal_id" { 
  description = "Principal ID of UAI (required for role assignment if UAI is used)"
  type        = string 
  default     = null 
}

# Security
variable "disk_encryption_set_id" {
  description = "ID of DES for CMK. Leave null if CMK not required."
  type        = string
  default     = null
}

# Network
variable "vnet_subnet_id" { type = string }

variable "network_profile" {
  type = object({
    network_plugin    = optional(string, "azure")
    network_policy    = optional(string, "azure")
    load_balancer_sku = optional(string, "Standard")
    outbound_type     = optional(string, "loadBalancer")
    dns_service_ip    = optional(string, "10.0.0.10")
    service_cidr      = optional(string, "10.0.0.0/16")
  })
  default = {} 
}

# Node Pools
variable "default_node_pool" {
  type = object({
    name                = string
    vm_size             = string
    zones               = optional(list(string), ["1", "2", "3"])
    node_count          = optional(number, 1)
    enable_auto_scaling = optional(bool, true)
    min_count           = optional(number, 1)
    max_count           = optional(number, 3)
    pod_limit           = optional(number, 110)
  })
}

variable "node_pools" {
  description = "Map of additional node pools"
  type = map(object({
    vm_size             = string
    zones               = optional(list(string), ["1", "2", "3"])
    node_count          = optional(number, 1)
    enable_auto_scaling = optional(bool, true)
    min_count           = optional(number, 1)
    max_count           = optional(number, 3)
    node_taints         = optional(list(string), [])
    node_labels         = optional(map(string), {})
    pod_limit           = optional(number, 110)
  }))
  default = {}
}