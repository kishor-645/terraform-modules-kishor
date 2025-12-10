# ========================================
# VNet Module
# ========================================
module "vnet" {
  source = "../../modules/Vnet"

  # Use the main RG where VNet resides
  resource_group_name = var.rg
  location            = var.location

  vnets = {
    vnet-test-tf = {
      name = "vnet-test-tf"
      address_space = ["10.0.0.0/16"]
      enable_ddos_protection = false
      subnets = {
        aks = {
          name           = "aks"
          address_prefix = "10.0.0.0/22"
        }
      }
    }
  }
}

# ========================================
# AKS Module
# ========================================
module "aks_dev" {
  source              = "../../modules/AKS-Cluster"

  aks_clusters = {
    "tf-aks-test" = {
      resource_group_name = var.rg
      location            = var.location
      dns_prefix          = "tfakstest"
      kubernetes_version  = "1.33.5"
      sku_tier            = "Free"
      
      # HERE IS HOW YOU LINK YOUR EXISTING SECONDARY RG
      node_resource_group     = var.rg_aks_nodes
      
      # Public access for dev environment
      private_cluster_enabled = false

      # Network config
      network_plugin = "azure"
      service_cidr   = "10.100.0.0/16"
      dns_service_ip = "10.100.0.10"

      # Reference VNet from module outputs correctly
      # [Vnet_Key][Subnet_Key]
      vnet_subnet_id = module.vnet.subnet_ids["vnet-test-tf"]["aks"]

      default_node_pool = {
        name                 = "agentpool"
        node_count           = 1
        vm_size              = "Standard_B4ms"
        auto_scaling_enabled = false
        # Setting zones to null/empty means "Let Azure pick" (cheaper for Dev/B-series)
        zones                = [] 
      }

      # Identity
      identity_type = "SystemAssigned"
      
      tags = { 
        Environment = "Development" 
      }
    }
  }
}