# ========================================
# VNet Module (Creating Hub + Spoke)
# ========================================
module "vnet" {
  source = "../../modules/Vnet"

  # Use the main RG where VNets reside
  resource_group_name = var.rg
  location            = var.location

  vnets = {
    # 1. The Hub VNet (Keys must match what you lookup later)
    (var.vnet) = {
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
        psql = {
          name           = "psql"
          address_prefix = "10.0.3.0/26"
          delegation = {
            name = "psql-delegation"
            service_delegation = {
              name    = "Microsoft.DBforPostgreSQL/flexibleServers"
              actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
        }
      }
    }

    # 2. The Spoke VNet (New)
    (var.vnet_spoke) = {
      name = var.vnet_spoke # Ensure this var is defined in variables.tf
      address_space = ["10.1.0.0/16"]
      enable_ddos_protection = false
      subnets = {
        (var.aks_subnet) = {
          name           = var.aks_subnet
          address_prefix = "10.1.0.0/22"
        }
      }
    }
  }
}

# ========================================
# VNet Peering Module (Hub <-> Spoke)
# ========================================
module "peering_hub_spoke" {
  source = "../../modules/Vnet-Peering"

  # Wait for VNets to exist before peering
  depends_on = [module.vnet]

  peerings = {
    "hub-to-spoke" = {
      # --- HUB SIDE (A) ---
      vnet_a_name = var.vnet
      # FIX: Retrieve ID from the Map output using the key defined above ("vnet-test-tf")
      vnet_a_id   = module.vnet.vnet_ids[var.vnet]
      vnet_a_rg   = var.rg

      # --- SPOKE SIDE (B) ---
      vnet_b_name = var.vnet_spoke
      # FIX: Retrieve ID from the Map output using the key defined above ("vnet-spoke")
      vnet_b_id   = module.vnet.vnet_ids[var.vnet_spoke]
      vnet_b_rg   = var.rg 

      # Connectivity Options
      allow_vnet_access       = true
      allow_forwarded_traffic = true
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
    "privatelink.postgres.database.azure.com"      # For Storage Blob
  ]

  # Link these zones to your VNet so Jumpbox/AKS can resolve them
  vnet_ids_to_link = {
    (var.vnet) = module.vnet.vnet_ids[var.vnet]
  }
  depends_on = [module.vnet]
}


module "postgres" {
  source = "../../modules/PostgreSQL"

  depends_on = [module.vnet, module.private_dns]

  name                = "psql-erp-tf"
  resource_group_name = var.rg
  location            = var.location
  
  # Admin Config
  admin_username = "master"
  admin_password = var.db_password # Assuming this is passed as a variable or random_string

  # Compute Spec (Matches your screenshot reqs)
  sku_name   = "GP_Standard_D2s_v3"
  storage_tier = "P10"
  storage_mb = 131072 # 128 GB
  
  # Network (Private Link Mode)
  # IMPORTANT: Set delegated_subnet_id to NULL if you plan to attach a Private Endpoint separately
  public_network_access_enabled = false
  delegated_subnet_id           = module.vnet.subnet_ids[var.vnet]["psql"]

  private_dns_zone_id = module.private_dns.dns_zone_ids["privatelink.postgres.database.azure.com"]


  # High Availability
  ha_mode      = "ZoneRedundant"
  zone         = "1"
  standby_zone = "2"

  # # CMK Encryption
  # cmk_enabled          = true
  # cmk_key_vault_key_id = azurerm_key_vault_key.psql_key.id
  # # One variable handles both the Identity Attachment and the CMK Config logic
  # cmk_identity_id      = module.psql_uai.identities["id-psql-prod"].id

  tags = { Environment = "test" }
}