# 1. CREATE IDENTITIES FIRST
module "uai_security" {
  source = "../../modules/User-Assigned-Identity"
  identities = {
    uai_id_cmk  = { name = var.uai_id_cmk, resource_group = var.rg, location = var.location }
    cluster_identity_uai  = { name = var.cluster_identity_uai, resource_group = var.rg, location = var.location }  
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
      principal_id = module.uai_security.identities.uai_id_cmk.principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "cmk-kv-crypto-identity-role-asgmt-cluster-uai" = {
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id = module.uai_security.identities.cluster_identity_uai.principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "cmk-key-reader-role-asgmt" = {
      role_definition_name = "Key Vault Reader"
      principal_id = module.uai_security.identities.uai_id_cmk.principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "cmk-key-reader-role-asgmt-cluster-uai" = {
      role_definition_name = "Key Vault Reader"
      principal_id = module.uai_security.identities.cluster_identity_uai.principal_id
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



# Create Disk Encryption Set (Call the NEW Module)
module "aks_des" {
  source = "../../modules/Disk-Encryption-Set"
  
  name                = var.des_name
  resource_group_name = var.rg
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.cmk_key_tf.versionless_id
  
  # Pass the identity you created
  identity_id         = module.uai_security.identities.cluster_identity_uai.id
}

resource "azurerm_role_assignment" "aks_contributor_on_des" {
  scope                = module.aks_des.id
  role_definition_name = "Contributor"
  principal_id         = module.uai_security.identities.cluster_identity_uai.principal_id

  depends_on = [module.aks_des]
}

# Create AKS Cluster (Call the NEW Simple Module)
module "aks" {
  source = "../../modules/AKS-Cluster"
  
  depends_on = [ azurerm_role_assignment.aks_contributor_on_des ]

  name                = var.aks_name
  resource_group_name = var.rg
  node_resource_group = var.rg_aks_nodes
  location            = var.location
  dns_prefix          = "aks-prod"
  
  # Network
  vnet_subnet_id = module.vnet.vnets["vnet-test-tf"].subnets["aks"].id
  network_profile = {
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
  }

  # Security Config (Simply pass the ID)
  private_cluster_enabled = false
  disk_encryption_set_id  = module.aks_des.id
  
  identity_id           = module.uai_security.identities.cluster_identity_uai.id
  identity_principal_id = module.uai_security.identities.cluster_identity_uai.principal_id

  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    node_count          = 1
  }
  
  # Extra Node Pools
  node_pools = {
    (var.user_pool) = {
      vm_size    = "Standard_E4s_v5"
      node_count = 1
    }
  }

  tags = { Environment = "Production" }
}