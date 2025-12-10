# ========================================
# Resource Group
# ========================================
module "rg_single" {
  source = "../../modules/RG"

  resource_groups = {
    "rg-test-tf" = {
      location = "uksouth"
      tags = {
        environment = "test"
      }
    }
  }

  common_tags = {
    project     = "test"
    managed_by  = "terraform"
  }
}

# ========================================
# VNet and subnet using the Vnet module
# ========================================
module "vnet" {
  source = "../../modules/Vnet"

  resource_group_name = "rg-test-tf"
  location            = "uksouth"

  vnets = {
    vnet-test-tf = {
      name = "vnet-test-tf"
      address_space = ["10.0.0.0/16"]
      enable_ddos_protection = false
      subnets = {
        test = {
          name           = "test"
          address_prefix = "10.0.0.0/24"
        }
      }
    }
  }
}
