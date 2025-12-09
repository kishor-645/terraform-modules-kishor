Azure Private Endpoints Module Guide

Purpose
- Create Private Endpoints for various PaaS services (Storage, Key Vault, SQL, etc.) connecting private network to Azure resources.

Inputs
- `resource_group_name`, `location`
- `private_endpoints` (map): `name`, `subnet_id`, `private_service_connection` block with `name`, `private_connection_resource_id`, `group_ids`.

Outputs
- `private_endpoints` map with `id` and `private_ip_addresses`.

Basic example
```hcl
module "pe" {
  source = "../../modules/Azure-Private-Endpoints"
  resource_group_name = "rg-network"
  private_endpoints = {
    "pe-storage" = {
      name = "pe-storage"
      subnet_id = var.subnet_id
      private_service_connection = { private_connection_resource_id = azurerm_storage_account.sa.id, group_ids = ["blob"] }
    }
  }
}
```

Notes
- Ensure the subnet allows private endpoints and does not have conflicting service endpoints.
- Use DNS records or Azure Private DNS Zone for name resolution (module may accept `private_dns_zone_id`).
