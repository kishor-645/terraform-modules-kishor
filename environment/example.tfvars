# ============================================================================
# TERRAFORM VARIABLES EXAMPLE FILE
# Real-world scenarios for multi-resource, fully dynamic modules
# ============================================================================
# Usage: terraform plan -var-file="environment/example.tfvars"
# ============================================================================

# ============================================================================
# RESOURCE GROUP MODULE - Multiple RGs for multi-environment deployment
# ============================================================================
resource_groups = {
  "rg-prod-eastus" = {
    location = "eastus"
    common_tags = {
      environment = "production"
      team        = "platform"
      cost_center = "1001"
    }
  }
  "rg-prod-westus" = {
    location = "westus"
    common_tags = {
      environment = "production"
      team        = "platform"
      cost_center = "1001"
    }
  }
  "rg-staging-eastus" = {
    location = "eastus"
    common_tags = {
      environment = "staging"
      team        = "platform"
      cost_center = "1002"
    }
  }
}

common_tags = {
  managed_by  = "terraform"
  project     = "intech-infra"
  created_at  = "2024-01-15"
}

# ============================================================================
# STORAGE ACCOUNTS - Multi-tier storage for different workloads
# ============================================================================
storage_accounts = {
  # High-performance storage for production workloads
  "stgprodapp001" = {
    resource_group_name      = "rg-prod-eastus"
    location                 = "eastus"
    account_tier             = "Standard"
    account_replication_type = "GRS"
    access_tier              = "Hot"
    https_traffic_only_enabled = true
    cmk_enabled              = true
    cmk_key_vault_key_id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-prod/keys/storage-key/version1"
    cmk_identity_id          = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mid-storage-prod"
    tags = {
      workload = "application"
      tier     = "premium"
    }
  }

  # Archive storage for long-term retention
  "stgprodarchive001" = {
    resource_group_name      = "rg-prod-eastus"
    location                 = "eastus"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    access_tier              = "Cool"
    https_traffic_only_enabled = true
    cmk_enabled              = false
    tags = {
      workload = "archive"
      tier     = "standard"
    }
  }

  # Staging storage with minimal redundancy
  "stgstaging001" = {
    resource_group_name      = "rg-staging-eastus"
    location                 = "eastus"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    access_tier              = "Hot"
    https_traffic_only_enabled = true
    cmk_enabled              = false
    tags = {
      workload = "testing"
      tier     = "basic"
    }
  }
}

# ============================================================================
# KEY VAULTS - Multiple vaults for different secret domains
# ============================================================================
key_vaults = {
  # Production application secrets
  "kv-prod-app" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    sku_name            = "premium"
    purge_protection_enabled = true
    soft_delete_retention_days = 90
    enable_rbac_authorization = true
    tags = {
      domain = "application"
      tier   = "premium"
    }
  }

  # Database credentials and encryption keys
  "kv-prod-db" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    sku_name            = "premium"
    purge_protection_enabled = true
    soft_delete_retention_days = 90
    enable_rbac_authorization = true
    tags = {
      domain = "database"
      tier   = "premium"
    }
  }

  # Staging vault with reduced protection
  "kv-staging" = {
    resource_group_name = "rg-staging-eastus"
    location            = "eastus"
    sku_name            = "standard"
    purge_protection_enabled = false
    soft_delete_retention_days = 30
    enable_rbac_authorization = true
    tags = {
      domain = "application"
      tier   = "standard"
    }
  }
}

# ============================================================================
# POSTGRESQL FLEXIBLE SERVERS - Multi-database deployment
# ============================================================================
postgresql_servers = {
  # Production primary database
  "psql-prod-primary" = {
    resource_group_name    = "rg-prod-eastus"
    location               = "eastus"
    sku_name               = "Standard_B4ms"
    storage_mb             = 131072  # 128 GB
    backup_retention_days  = 35
    geo_redundant_backup   = true
    zone                   = 1
    
    admin_username = "pgadmin"
    admin_password = "ComplexPassword123!@#" # Use sensitive data source in production
    
    authentication_enabled = true
    password_auth_enabled  = true
    
    cmk_enabled            = true
    cmk_key_vault_key_id   = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-prod-db/keys/psql-cmk/version1"
    
    tags = {
      tier       = "production"
      replication = "primary"
    }
  }

  # Production replica in different region
  "psql-prod-replica" = {
    resource_group_name   = "rg-prod-westus"
    location              = "westus"
    sku_name              = "Standard_B4ms"
    storage_mb            = 131072
    backup_retention_days = 35
    geo_redundant_backup  = false  # Replicas don't need additional geo-backup
    zone                  = 1
    
    admin_username = "pgadmin"
    admin_password = "ComplexPassword123!@#"
    
    authentication_enabled = true
    password_auth_enabled  = true
    
    cmk_enabled            = true
    cmk_key_vault_key_id   = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-prod-db/keys/psql-cmk/version1"
    
    tags = {
      tier       = "production"
      replication = "replica"
    }
  }

  # Staging database with reduced resources
  "psql-staging" = {
    resource_group_name   = "rg-staging-eastus"
    location              = "eastus"
    sku_name              = "Standard_B2s"
    storage_mb            = 32768  # 32 GB
    backup_retention_days = 14
    geo_redundant_backup  = false
    zone                  = 1
    
    admin_username = "pgadmin"
    admin_password = "ComplexPassword123!@#"
    
    authentication_enabled = true
    password_auth_enabled  = true
    
    cmk_enabled            = false  # CMK optional for staging
    
    tags = {
      tier = "staging"
    }
  }
}

# ============================================================================
# AZURE CONTAINER REGISTRIES - Multi-registry strategy
# ============================================================================
registries = {
  # Production registry with premium features
  "acr-prod-us" = {
    resource_group_name           = "rg-prod-eastus"
    location                      = "eastus"
    sku                           = "Premium"
    admin_enabled                 = false
    public_network_access_enabled = false
    
    cmk_enabled              = true
    cmk_key_vault_key_id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-prod-acr/keys/acr-cmk/version1"
    cmk_identity_id          = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mid-acr-prod"
    
    tags = {
      tier        = "production"
      region      = "us"
      availability = "high"
    }
  }

  # Staging registry with basic features
  "acr-staging-us" = {
    resource_group_name           = "rg-staging-eastus"
    location                      = "eastus"
    sku                           = "Basic"
    admin_enabled                 = true
    public_network_access_enabled = false
    
    cmk_enabled = false
    
    tags = {
      tier = "staging"
    }
  }

  # Development registry with public access (for testing)
  "acr-dev-us" = {
    resource_group_name           = "rg-staging-eastus"
    location                      = "eastus"
    sku                           = "Standard"
    admin_enabled                 = true
    public_network_access_enabled = true
    
    cmk_enabled = false
    
    tags = {
      tier = "development"
    }
  }
}

# ============================================================================
# USER-ASSIGNED IDENTITIES - Security principals for service accounts
# ============================================================================
user_assigned_identities = {
  "mid-acr-prod" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    tags = {
      purpose = "acr-encryption"
      tier    = "production"
    }
  }

  "mid-storage-prod" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    tags = {
      purpose = "storage-encryption"
      tier    = "production"
    }
  }

  "mid-aks-kubelet" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    tags = {
      purpose = "aks-node-identity"
      tier    = "production"
    }
  }
}

# ============================================================================
# VNET - Core networking for all resources
# ============================================================================
vnets = {
  "vnet-prod-eastus" = {
    resource_group_name = "rg-prod-eastus"
    location            = "eastus"
    address_space       = ["10.0.0.0/16"]
    
    subnets = {
      "subnet-aks" = {
        address_prefixes = ["10.0.1.0/24"]
      }
      "subnet-database" = {
        address_prefixes = ["10.0.2.0/24"]
      }
      "subnet-appgw" = {
        address_prefixes = ["10.0.3.0/24"]
      }
    }
    
    tags = {
      tier = "production"
    }
  }

  "vnet-staging-eastus" = {
    resource_group_name = "rg-staging-eastus"
    location            = "eastus"
    address_space       = ["10.100.0.0/16"]
    
    subnets = {
      "subnet-aks" = {
        address_prefixes = ["10.100.1.0/24"]
      }
      "subnet-database" = {
        address_prefixes = ["10.100.2.0/24"]
      }
    }
    
    tags = {
      tier = "staging"
    }
  }
}

# ============================================================================
# COMMON CONFIGURATION
# ============================================================================
environment = "production"
project_name = "intech-platform"
managed_by   = "terraform"
