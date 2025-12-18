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
      name = var.vnet
      address_space = ["10.0.0.0/16"]
      enable_ddos_protection = false
      subnets = {

        (var.private_endpoint_subnet) = {
          name           = var.private_endpoint_subnet
          address_prefix = "10.0.0.0/24"
        }
        (var.jumpbox_subnet) = {
          name           = var.jumpbox_subnet
          address_prefix = "10.0.1.0/24"
        }
        firewall = {
          name           = "AzureFirewallSubnet"
          address_prefix = "10.0.2.0/26"
        }
        (var.aks_subnet) = {
          name           = var.aks_subnet
          address_prefix = "10.0.100.0/22"
        
        }
        (var.agfc_subnet) = {
          name           = var.agfc_subnet
          address_prefix = "10.0.3.0/24"
          delegation = {
            name = var.agfc_subnet
            service_delegation = {
              name    = "Microsoft.ServiceNetworking/trafficControllers"
              actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
        }
      }
    }
  }
}


# ========================================
# Private DNS Zones & VNet Linking
# ========================================
module "private_dns" {
  source              = "../../modules/Private-DNS-Zone"
  resource_group_name = var.rg

  # Create standard zones for the resources you are using
  dns_zone_names = [
    "privatelink.vaultcore.azure.net",       # For Key Vault
    "privatelink.azurecr.io",                # For ACR
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net"      # For Storage Blob
  ]

  # Link these zones to your VNet so Jumpbox/AKS can resolve them
  vnet_ids_to_link = {
    (var.vnet) = module.vnet.vnet_ids[var.vnet]
  }
  depends_on = [module.vnet]
}


# 1. CREATE IDENTITIES FIRST
module "uai_security" {
  source = "../../modules/User-Assigned-Identity"
  identities = {
    (var.uai_id_cmk)  = { name = var.uai_id_cmk, resource_group = var.rg, location = var.location }
    (var.cluster_identity_uai)  = { name = var.cluster_identity_uai, resource_group = var.rg, location = var.location }  
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
module "acr" {
  source = "../../modules/Azure-Container-Registries"
  
    registries = {
    (var.acr_name) = {
      resource_group_name           = var.rg
      location                      = var.location
      sku                           = "Premium"
      admin_enabled                 = true
      public_network_access_enabled = false

      cmk_enabled            = true
      cmk_key_vault_key_id   = azurerm_key_vault_key.cmk_key_tf.versionless_id
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
    (var.storage_account) = {
      account_tier                      = "Standard"
      account_replication_type          = "LRS"
      public_network_access_enabled     = false
      infrastructure_encryption_enabled = true
      cmk_enabled                       = true
      cmk_key_vault_key_id              = azurerm_key_vault_key.cmk_key_tf.versionless_id
      cmk_user_assigned_identity_id     = module.uai_security.identities[var.uai_id_cmk].id
      tags = {
        encryption = "cmk"
      }
    }
  }
  depends_on = [azurerm_key_vault_key.cmk_key_tf]
}


#=======================================
# linux vm - agent vm
#=======================================

module "jumpbox_public" {
  source              = "../../modules/Linux-VM"
  vm_name             = "vm-test-public"
  resource_group_name = var.rg
  location            = var.location
  subnet_id           = module.vnet.subnet_ids[var.vnet][var.jumpbox_subnet] 
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
 depends_on = [module.vnet]
}


# ========================================
# Private Endpoints Configuration
# ========================================
module "private_endpoints" {
  source              = "../../modules/Private-Endpoints"
  resource_group_name = var.rg
  location            = var.location

  private_endpoints = {
    # 1. Key Vault Endpoint
    (var.pe_kv) = {
      subnet_id                      = module.vnet.subnet_ids[var.vnet][var.private_endpoint_subnet]
      private_connection_resource_id = module.kv_premium.key_vaults[var.cmk_kv].id
      subresource_names              = ["vault"]
      private_dns_zone_ids           = [module.private_dns.dns_zone_ids["privatelink.vaultcore.azure.net"]]
    },

    # 2. ACR Endpoint
    (var.pe_acr) = {
      subnet_id                      = module.vnet.subnet_ids[var.vnet][var.private_endpoint_subnet]
      private_connection_resource_id = module.acr.acr_ids[var.acr_name]
      subresource_names              = ["registry"]
      private_dns_zone_ids           = [module.private_dns.dns_zone_ids["privatelink.azurecr.io"]]
    },

    # 3. Storage Account Endpoint (Blob)
    (var.pe_stg_blob) = {
      subnet_id                      = module.vnet.subnet_ids[var.vnet][var.private_endpoint_subnet]
      private_connection_resource_id = module.storage_cmk.storage_accounts[var.storage_account].id
      subresource_names              = ["blob"]
      private_dns_zone_ids           = [module.private_dns.dns_zone_ids["privatelink.blob.core.windows.net"]]
    },
     
   # 3. Storage Account Endpoint (Blob)
    (var.pe_stg_file) = {
      subnet_id                      = module.vnet.subnet_ids[var.vnet][var.private_endpoint_subnet]
      private_connection_resource_id = module.storage_cmk.storage_accounts[var.storage_account].id
      subresource_names              = ["file"]
      private_dns_zone_ids           = [module.private_dns.dns_zone_ids["privatelink.file.core.windows.net"]]
    }
  }

  # Ensure resources exist before creating endpoints
  depends_on = [
    module.kv_premium,
    module.acr,
    module.storage_cmk,
    module.vnet,
    module.private_dns
  ]
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


# ========================================
# Azure Firewall Module
# ========================================

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
  subnet_id            = module.vnet.subnet_ids[var.vnet]["AzureFirewallSubnet"]
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
      translated_address  = "10.0.100.100" # Replace with your AKS Internal Ingress Service IP
      translated_port     = 443           # Traffic usually maps to 80/443 inside LB
    },
        {
      name                = "Inbound-to-AKS-http"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["80"]
      translated_address  = "10.0.100.100" # Replace with your AKS Internal Ingress Service IP
      translated_port     = 80          # Traffic usually maps to 80/443 inside LB
    },
    {
      name                = "jumpbox-ssh"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.fw_pip.ip_address
      destination_ports   = ["50022"]
      translated_address  = "10.0.1.4"   # Replace with your Jumpbox VM Private IP
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
      source_addresses      = ["10.0.100.0/22"] # Your AKS Subnet
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
      source_addresses  = ["10.0.100.0/22"]
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
      source_addresses  = ["10.0.100.0/22"]
      destination_fqdns = [
        "management.azure.com",
        "login.microsoftonline.com",
        "*.ods.opinsights.azure.com",
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
      source_addresses  = ["10.0.100.0/22"]
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
      source_addresses  = ["10.0.100.0/22"]
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
      source_addresses  = ["10.0.100.0/22"]
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



module "udr_spoke" {
  source              = "../../modules/Route-Table"
  name                = var.route_table_name
  resource_group_name = var.rg
  location            = var.location

  bgp_route_propagation_enabled = false

  # 1. Define Routes
  routes = {
    "default-to-firewall" = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.firewall_private_ip
    },

    # -------------------------------------------------------------
    # 2. THE TEMPORARY BYPASS (Creation Fix)
    # These two routes cover the whole internet but are more specific 
    # than /0, so they override the firewall route automatically.
    # -------------------------------------------------------------
    "temp-bypass-lower-half" = {
      address_prefix = "0.0.0.0/1"
      next_hop_type  = "Internet"
    },
    "temp-bypass-upper-half" = {
      address_prefix = "128.0.0.0/1"
      next_hop_type  = "Internet"
    },

    "private-traffic" = {
      # Optional: Specific bypass route if needed
      address_prefix = "10.0.0.0/16"
      next_hop_type  = "VnetLocal"
    }
  }

  # 2. Associate to Subnets
  subnet_ids = {
    "aks-subnet" = module.vnet.subnet_ids[var.vnet][var.aks_subnet],
    "private-endpoint-subnet" = module.vnet.subnet_ids[var.vnet][var.private_endpoint_subnet]
  }
  depends_on = [module.vnet, module.firewall]
}

# ========================================
# AKS Cluster with Disk Encryption Set (CMK)
# ========================================
# Create Disk Encryption Set (Call the NEW Module)
module "aks_des" {
  source = "../../modules/Disk-Encryption-Set"

  depends_on = [ azurerm_key_vault_key.cmk_key_tf ]
  
  name                = var.des_name
  resource_group_name = var.rg
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.cmk_key_tf.versionless_id
  auto_key_rotation_enabled = true

  # Pass the identity you created
  identity_id         = module.uai_security.identities[var.uai_id_cmk].id
}

resource "azurerm_role_assignment" "aks_contributor_on_des" {
  scope                = module.aks_des.id
  role_definition_name = "Contributor"
  principal_id         = module.uai_security.identities[var.cluster_identity_uai].principal_id

  depends_on = [module.aks_des]
}

# Create AKS Cluster (Call the NEW Simple Module)
module "aks" {
  source = "../../modules/AKS-Cluster"
  
  depends_on = [ azurerm_role_assignment.aks_contributor_on_des, module.udr_spoke ]

  name                = var.aks_name
  resource_group_name = var.rg
  node_resource_group = var.rg_aks_nodes
  location            = var.location
  kubernetes_version  = "1.33.5"
  sku_tier            = "Standard"
  dns_prefix          = "aks-prod"

  rbac_enabled = true
  
  # --- ENABLE SECURITY FEATURES ---
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Network
  vnet_subnet_id = module.vnet.subnet_ids[var.vnet][var.aks_subnet]
  
  network_profile = {
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
    network_plugin    = "azure"
    network_plugin_mode = "overlay"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type    = "loadBalancer"
    }

  # Security Config (Simply pass the ID)
  private_cluster_enabled = true
  disk_encryption_set_id  = module.aks_des.id
  
  identity_id           = module.uai_security.identities[var.cluster_identity_uai].id
  identity_principal_id = module.uai_security.identities[var.cluster_identity_uai].principal_id

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