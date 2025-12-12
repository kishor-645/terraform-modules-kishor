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
        firewall = {
          name           = "AzureFirewallSubnet"
          address_prefix = "10.0.4.0/26"
        }
        aks = {
          name           = "aks"
          address_prefix = "10.0.0.0/22"
        }
      }
    }
  }
}

# Public IP for Firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "az-fw-tf-test-pip"
  resource_group_name = var.rg
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

module "firewall" {
  source = "../../modules/Azure-Firewall"

  # --- Basic Info ---
  resource_group_name  = var.rg
  location             = var.location
  firewall_name        = "afw-tf-test"
  firewall_sku_name    = "AZFW_VNet"
  firewall_sku_tier    = "Premium" 
  firewall_policy_name = "afw-policy-tf-test"

  # --- Networking ---
  subnet_id            = module.vnet.subnet_ids["vnet-test-tf"]["AzureFirewallSubnet"]
  public_ip_address_id = azurerm_public_ip.fw_pip.id
  zones                = ["1", "2", "3"]

  # --- Phase 1: Security Configuration (Disabled features) ---
  # Threat Intel is ON (Alert), everything else is OFF for initial testing
  threat_intelligence_mode              = "Alert"
  threat_intelligence_allowlist_enabled = false
  
  dns_proxy_enabled      = false
  dns_servers            = []
  
  tls_inspection_enabled = false
  idps_mode              = "Off"
  
  # =========================================================================
  # 1. DNAT Rules (Inbound)
  # =========================================================================
  # NOTE: Replace '10.0.0.100' or '10.0.1.4' with your ACTUAL Internal IP of your
  # Ingress Controller Load Balancer or Jumpbox VM.
  # =========================================================================
  nat_rules = [
    {
      name                = "Inbound-to-AKS-https"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["443"]
      translated_address  = "10.0.0.100" # Replace with your AKS Internal Ingress Service IP
      translated_port     = 443           # Traffic usually maps to 80/443 inside LB
    },
        {
      name                = "Inbound-to-AKS-http"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["80"]
      translated_address  = "10.0.0.100" # Replace with your AKS Internal Ingress Service IP
      translated_port     = 80          # Traffic usually maps to 80/443 inside LB
    },
    {
      name                = "jumpbox-ssh"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["50022"]
      translated_address  = "10.0.1.10"   # Replace with your Jumpbox VM Private IP
      translated_port     = 22
    },
    {
      name                = "jumpbox-https-tunnel"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["4443"]     # Changed to 4443 to avoid conflict with AKS 443
      translated_address  = "10.0.1.4"   # Replace with your Jumpbox VM Private IP
      translated_port     = 443
    }
  ]

  # =========================================================================
  # 2. Network Rules (L3/L4)
  # =========================================================================
  network_rules = [
    # 100: Azure Core Services
    {
      name                  = "Azure-Services"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/22"] # Your AKS Subnet
      destination_addresses = [
        "AzureCloud.uksouth", 
        "AzureCloud.ukwest", 
        "AzureKeyVault",
        "AzureCloud"
      ]
      destination_ports     = ["443"]
      destination_fqdns     = []
    },
    # 110: NTP & DNS
    {
      name                  = "DNS-NTP"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/16"] # Entire VNet
      destination_addresses = ["*"]
      destination_ports     = ["123"] # NTP
      destination_fqdns     = []
    },
    {
      name                  = "Azure-DNS"
      protocols             = ["UDP", "TCP"]
      source_addresses      = ["10.0.0.0/16"] 
      destination_addresses = ["168.63.129.16"] # Azure Recursive DNS IP
      destination_ports     = ["53"] 
      destination_fqdns     = []
    },
    # 120: Internal Traffic
    {
      name                  = "Internal-VNet-Communication"
      protocols             = ["Any"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["10.0.0.0/16"]
      destination_ports     = ["*"]
      destination_fqdns     = []
    },
    # 130: Jumpbox to Internet (If needed)
    {
      name                  = "Jumpbox-Internet"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.0.1.0/24"] # Your Jumpbox Subnet range
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      destination_fqdns     = []
    }
  ]

  # =========================================================================
  # 3. Application Rules (L7 / FQDN)
  # =========================================================================
  application_rules = [
    # 100: AKS Control Plane Required FQDNs
    {
      name              = "AKS-Control-Plane"
      source_addresses  = ["10.0.0.0/22"]
      destination_fqdns = [
        "*.hcp.uksouth.azmk8s.io",
        "*.tun.uksouth.azmk8s.io",
        "ifconfig.me",
        "registry-1.docker.io",
        "auth.docker.io",
        "*.cloudflare.docker.com", # cloudflarestorage.com alias
        "*.docker.com"
      ]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = false
      web_categories    = []
    },
    # 110: Azure Management
    {
      name              = "Azure-Services-Apps"
      source_addresses  = ["10.0.0.0/22"]
      destination_fqdns = [
        "management.azure.com",
        "login.microsoftonline.com",
        "*.ods.opinsights.azure.com", # Azure Monitor
        "*.oms.opinsights.azure.com",
        "dc.services.visualstudio.com"
      ]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = false
      web_categories    = []
    },
    # 120: Container Registries (ACR/MCR)
    {
      name              = "Container-Registries"
      source_addresses  = ["10.0.0.0/22"]
      destination_fqdns = [
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "*.azurecr.io",
        "*.blob.core.windows.net", # Required for ACR layers
        "*.file.core.windows.net"  # Sometimes required for PVs
      ]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = false
      web_categories    = []
    },
    # 130: Linux OS Updates
    {
      name              = "OS-Updates"
      source_addresses  = ["10.0.0.0/22"]
      destination_fqdns = [
        "*.ubuntu.com",
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "packages.microsoft.com"
      ]
      protocol_type     = "Https"
      protocol_port     = 443
      terminate_tls     = false
      web_categories    = []
    },
    # 130b: OS Updates (HTTP often used for GPG keys)
    {
      name              = "OS-Updates-HTTP"
      source_addresses  = ["10.0.0.0/22"]
      destination_fqdns = [
        "*.ubuntu.com",
        "security.ubuntu.com",
        "azure.archive.ubuntu.com"
      ]
      protocol_type     = "Http"
      protocol_port     = 80
      terminate_tls     = false
      web_categories    = []
    }
  ]
}

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
    "cmk-key-reader-role-asgmt" = {
      role_definition_name = "Key Vault Reader"
      principal_id = module.uai_security.identities.uai_id_cmk.principal_id
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
# Role-Assignment for Cluster Identity over keyvault-CMK
# ========================================
module "ra-aks" {
  source = "../../modules/Role-Assignment"
  role_assignments = {
    "cmk-kv-crypto-identity-role-asgmt-cluster-uai" = {
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id = module.uai_security.identities.cluster_identity_uai.principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
    "cmk-key-reader-role-asgmt-cluster-uai" = {
      role_definition_name = "Key Vault Reader"
      principal_id = module.uai_security.identities.cluster_identity_uai.principal_id
      scope = module.kv_premium.key_vaults[var.cmk_kv].id
    }
  }
  depends_on = [module.kv_premium, module.uai_security]

}

# Create Disk Encryption Set (Call the NEW Module)
module "aks_des" {
  source = "../../modules/Disk-Encryption-Set"
  
  name                = var.des_name
  resource_group_name = var.rg
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.cmk_key_tf.versionless_id
  auto_key_rotation_enabled = true

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
  kubernetes_version  = "1.33.5"
  sku_tier            = "Free"
  dns_prefix          = "aks-prod"
  
  
  # Network
  vnet_subnet_id = module.vnet.subnet_ids["vnet-test-tf"]["aks"]
  
  network_profile = {
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type    = "userDefinedRouting"
    }

  # Security Config (Simply pass the ID)
  private_cluster_enabled = true
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

  tags = { Environment = "tfTest" }
}


#=======================================
# linux vm - agent vm
#=======================================

module "jumpbox_public" {
  source              = "../../modules/Linux-VM"
  vm_name             = "vm-test-public"
  resource_group_name = var.rg
  location            = var.location
  subnet_id           = module.vnet.subnet_ids["vnet-test-tf"]["aks"]
  
  vm_size          = "Standard_B2ms"
  enable_public_ip = true
  image_key        = "ubuntu22"
  
  admin_username = "master"
  admin_password = "DevSecOps@25"
  ssh_public_key = null # Forces password auth to be enabled

  nsg_rules = [
    {
      name                       = "AllowSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}