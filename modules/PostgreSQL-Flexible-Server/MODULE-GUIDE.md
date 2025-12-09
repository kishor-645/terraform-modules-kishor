PostgreSQL Flexible Server Module Guide

Purpose
- Provision Azure Database for PostgreSQL - Flexible Server instances with networking options (private access) and backup/monitoring settings.

Inputs
- `resource_group_name`, `location`
- `postgres_servers` (map): `name`, `sku_name`, `version`, `vnet_subnet_id`, `public_access` (bool), `admin_username`, `admin_password` (prefer KeyVault/secret)

Outputs
- `postgres_servers` map with `id`, `fqdn`, `private_endpoint_ids`.

Basic example
```hcl
module "pg" {
  source = "../../modules/PostgreSQL-Flexible-Server"
  resource_group_name = "rg-db"
  postgres_servers = {
    "pg-prod" = { name = "pg-prod", sku_name = "Standard_D2s_v3", version = "13", vnet_subnet_id = var.subnet_db }
  }
}
```

Notes
- Prefer private access using Private Endpoint and disable public network access for production.
- Store DB admin credentials in Key Vault and reference via data sources or KeyVault provider.
