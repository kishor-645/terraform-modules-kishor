# 1. CREATE IDENTITIES FIRST
module "uai_security" {
  source = "../../modules/User-Assigned-Identity"
  identities = {
    (var.uai_id_cmk)  = { name = "id-cmk-tf-test", resource_group = var.rg, location = var.location }
  }
}

# 2. CREATE KEY VAULT (Wait for identities implicitly via dependency, not strictly required yet)
data "azurerm_client_config" "current" {}
# ========================================
# Key vault HSM creation
# ========================================
module "kv_premium" {
  source = "../../modules/Key-Vaults"

  resource_group_name = var.rg
  location            = var.location

  key_vaults = {
    (var.cmk_kv) = {
      sku_name                      = "premium"  # Premium enables HSM
      auth_type                     = "rbac"
      public_network_access_enabled = true
      soft_delete_retention_days    = 7  # Minimum required by Azure (7-90 days)
      purge_protection_enabled      = true  # Disable purge protection to allow immediate purge after soft delete
    }
  }

  # # Use RBAC as default for vaults created by this module
  # default_auth_type = "rbac"

  common_tags = {
    environment = "tf-test"
    compliance  = "pci-dss"
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
      principal_id = module.uai_security.identities[var.uai_id_cmk].principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "cmk-key-reader-role-asgmt" = {
      role_definition_name = "Key Vault Reader"
      principal_id = module.uai_security.identities[var.uai_id_cmk].principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "Keyvault-admin-on-Service-Principle" = {
      role_definition_name = "Key Vault Administrator"
      principal_id = data.azurerm_client_config.current.object_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
  }
  depends_on = [module.kv_premium, module.uai_security]

}


# 4. CREATE KEY (Use 'depends_on' to ensure Admin permissions exist)
resource "azurerm_key_vault_key" "cmk_key_tf" {
  name         = var.cmk_kv_key
  key_vault_id = module.kv_premium.key_vaults[var.cmk_kv].id
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  # Terraform creates this key, so the USER running Terraform needs permissions
  # depends_on = [azurerm_role_assignment.tf_kv_admin]
  depends_on = [module.ra, module.kv_premium]

}

# DEPLOY RESOURCES (Explicit dependency)
module "acr_dev" {
  source = "../../modules/Azure-Container-Registries"
  
    registries = {
    "tftestacr999877" = {
      resource_group_name           = var.rg
      location                      = var.location
      sku                           = "Premium"
      admin_enabled                 = true
      public_network_access_enabled = true

      cmk_enabled            = true
      cmk_key_vault_key_id   = azurerm_key_vault_key.(var.cmk_kv_key).versionless_id
      cmk_identity_id        = module.uai_security.identities[var.uai_id_cmk].id
      cmk_identity_client_id = module.uai_security.identities[var.uai_id_cmk].client_id
    }
  }

  # ACR cannot be created until the Key exists AND the UAI has permissions to it
  depends_on = [azurerm_key_vault_key.cmk_key_tf]

}
# ========================================
# Storage account with CMK
# ========================================
module "storage_cmk" {
  source = "../../modules/Storage-Accounts"

  resource_group_name = var.rg
  location            = var.location

  storage_accounts = {
    "stactftest64555" = {
      account_tier                      = "Standard"
      account_replication_type          = "LRS"
      infrastructure_encryption_enabled = true
      cmk_enabled                       = true
      cmk_key_vault_key_id              = azurerm_key_vault_key.(var.cmk_kv_key).id
      cmk_user_assigned_identity_id     = module.uai_security.identities[var.uai_id_cmk].id
      tags = {
        encryption = "cmk"
      }
    }
  }

  depends_on = [azurerm_key_vault_key.cmk_key_tf]
}
