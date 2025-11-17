# ========================================
# Log Analytics Workspace
# ========================================
module "mylog" {
  source = "../../modules/Log-Analytics-Workspace"

  workspace_name      = "multirg-loganalytics-tf-test"
  resource_group_name = "multi-region-terraform-test-rg"
  location            = "canadacentral"
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}



# ========================================
# ACR - Container Registry
# ========================================
module "acr_dev" {
  source = "../../modules/Azure-Container-Registries"

  acr_name                      = "acrdevtest001tftest"
  resource_group_name           = "multi-region-terraform-test-rg"
  location                      = "canadacentral"
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = true

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Diagnostic Settings for ACR
module "acr_diagnostics" {
  source = "../../modules/Diagnostic-Settings"

  diagnostic_setting_name = "diag-acr-test"
  target_resource_id      = module.acr_dev.acr_id
  log_analytics_workspace_id = module.mylog.workspace_id

  enabled_logs = [
    # {
    #   category       = "ContainerRegistryRepositoryEvents"
    #   category_group = null
    # },
    # {
    #   category       = "ContainerRegistryLoginEvents"
    #   category_group = null
    # },
    {
        category       = null
        category_group = "audit"
    }
  ]

  enabled_metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
  depends_on = [
    module.acr_dev,
    module.mylog,
  ]
}