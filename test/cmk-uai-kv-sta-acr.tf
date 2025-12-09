# 1. CREATE IDENTITIES FIRST
module "uai_security" {
  source = "../../modules/User-Assigned-Identity"
  identities = {
    "id-acr-cmk"   = { name = "id-acr-cmk", resource_group = var.rg, location = var.location }
    "id-pgsql-cmk" = { name = "id-pgsql-cmk", resource_group = var.rg, location = var.location }
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
    "tf-cmk-vault-test2" = {
      sku_name                      = "premium"  # Premium enables HSM
      auth_type = "rbac"
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

# The Identity needs permission BEFORE any service tries to use the Key
resource "azurerm_role_assignment" "acr_identity_kv_permission" {
  scope                = module.kv_premium.key_vaults["tf-cmk-vault-test2"].id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = module.uai_security.identities["id-acr-cmk"].principal_id
}

# 4. CREATE KEY (Use 'depends_on' to ensure Admin permissions exist)
resource "azurerm_key_vault_key" "acr_cmk_key" {
  name         = "acr-cmk-key"
  key_vault_id = module.kv_premium.key_vaults["tf-cmk-vault-test2"].id
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  # Terraform creates this key, so the USER running Terraform needs permissions
  depends_on = [azurerm_role_assignment.tf_kv_admin]
}

# 5. DEPLOY RESOURCES (Explicit dependency)
module "acr_dev" {
  source = "../../modules/Azure-Container-Registries"
  
  # ACR cannot be created until the Key exists AND the UAI has permissions to it
  depends_on = [
    azurerm_key_vault_key.acr_cmk_key,
    azurerm_role_assignment.acr_identity_kv_permission
  ]

  registries = {
    "erp-acr" = {
      # ... config
      cmk_enabled            = true
      cmk_key_vault_key_id   = azurerm_key_vault_key.acr_cmk_key.versionless_id
      cmk_identity_id        = module.uai_security.identities["id-acr-cmk"].id
      cmk_identity_client_id = module.uai_security.identities["id-acr-cmk"].client_id
    }
  }
}