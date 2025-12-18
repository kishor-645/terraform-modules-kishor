# 3. Create Server
module "postgres" {
  source = "../../modules/PostgreSQL-Flexible-Server"

  name                = "psql-erp-prod"
  resource_group_name = var.rg_name
  location            = var.location
  
  # Capacity
  sku_name   = "GP_Standard_D4s_v3"
  storage_mb = 131072 # 128GB

  # Admin
  admin_username = "psqladmin"
  admin_password = var.db_password # Get from KeyVault

  # Networking (Private Link Mode)
  public_network_access_enabled = false
  delegated_subnet_id           = null # We use PE, not Delegation

  # High Availability (Zone Redundant)
  ha_mode      = "ZoneRedundant"
  zone         = "1"
  standby_zone = "2"

  # CMK Security
  cmk_enabled                   = true
  cmk_key_vault_key_id          = azurerm_key_vault_key.psql.id
  cmk_user_assigned_identity_id = module.psql_uai.identities["id-psql-prod"].id
  identity_id                   = module.psql_uai.identities["id-psql-prod"].id

  tags = { Environment = "Production" }
}