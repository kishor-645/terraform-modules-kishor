# ========================================
# Resource Group
# ========================================
# module "rg_single" {
#   source = "../../modules/RG"

#   resource_groups = {
#     "rg-test-tf" = {
#       location = "uksouth"
#       tags = {
#         environment = "test"
#       }
#     }
#   }

#   common_tags = {
#     project     = "test"
#     managed_by  = "terraform"
#   }
# }

# ========================================
# VNet and subnet using the Vnet module
# ========================================
# module "vnet" {
#   source = "../../modules/Vnet"

#   resource_group_name = "rg-test-tf"
#   location            = "uksouth"

#   vnets = {
#     vnet-test-tf = {
#       name = "vnet-test-tf"
#       address_space = ["10.0.0.0/16"]
#       enable_ddos_protection = false
#       subnets = {
#         test = {
#           name           = "test"
#           address_prefix = "10.0.0.0/24"
#         }
#       }
#     }
#   }
# }

# ========================================
# Key vault HSM creation
# ========================================
module "kv_premium_cmk" {
  source = "../../modules/Key-Vaults"

  resource_group_name = "rg-test-tf"
  location            = "uksouth"

  key_vaults = {
    "tf-cmk-vault-test1" = {
      sku_name                      = "premium"  # Premium enables HSM
      auth_type = "rbac"
      public_network_access_enabled = true
      soft_delete_retention_days    = 7  # Minimum required by Azure (7-90 days)
      purge_protection_enabled      = false  # Disable purge protection to allow immediate purge after soft delete
    }
  }

  # # Use RBAC as default for vaults created by this module
  # default_auth_type = "rbac"

  common_tags = {
    environment = "tf-test"
    compliance  = "pci-dss"
  }
}

# Use vault URI with Key Vault Key resource
resource "azurerm_key_vault_key" "tf-cmk-key" {
  name            = "tf-cmk-key"
  key_vault_id    = module.kv_premium_cmk.key_vaults["tf-cmk-vault-test1"].id
  # Use HSM-backed key
  key_type        = "RSA-HSM"
  key_size        = 2048
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}


# ========================================
# UAI - For CMK
# ========================================
module "uai-cmk" {
  source = "../../modules/User-Assigned-Identity"

  identities = {
    cmk-identity-uai = {
      name           = ""
      resource_group = "rg-test-tf"
      location       = "uksouth"
    }
  }
}


# ========================================
# Role-Assignment for keyvault-CMK over identity
# ========================================
module "ra" {
  source = "../../modules/Role-Assignment"
  role_assignments = {
    "cmk-kv-crypto-identity-role-asgmt" = {
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id = module.uai-cmk.cmk_identity-uai.principal_id
      scope = module.kv_premium_cmk.key_vaults["tf-cmk-vault-test1"].id
    }
  }
}

# ========================================
# ACR - Container Registry
# ========================================
module "acr_dev" {
  source = "../../modules/Azure-Container-Registries"

  acr_name                      = "tftestacr645"
  resource_group_name           = "rg-test-tf"
  location                      = "uksouth"
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = true

 # CMK Encryption
  encryption_key_vault_key_id = azurerm_key_vault_key.tf-cmk-key.id
  encryption_identity_id      = azurerm_user_assigned_identity.cmk-identity-uai.id

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# ========================================
# Storage account with CMK
# ========================================
module "storage_cmk" {
  source = "../../modules/Storage-Accounts"

  resource_group_name = "rg-test-tf"
  location            = "uksouth"

  storage_accounts = {
    "stactftest645" = {
      account_tier                      = "Standard"
      account_replication_type          = "LRS"
      infrastructure_encryption_enabled = true
      cmk_enabled                       = true
      cmk_key_vault_key_id              = module.key_vault_key_id["tf-cmk-key"].id
      cmk_user_assigned_identity_id     = module.uai.identities["cmk-identity-uai"].id
      tags = {
        encryption = "cmk"
      }
    }
  }

  common_tags = {
    environment = "production"
    security    = "high"
  }
}
