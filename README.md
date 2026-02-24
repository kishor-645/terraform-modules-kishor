# Terraform Modules for Azure

This repository contains reusable Terraform modules and environment-level root configurations for Azure infrastructure.

## Repository layout

```text
terraform-modules-kishor/
├── modules/                # Reusable Terraform modules
├── environment/
│   ├── dev/                # Root module for dev-style deployment
│   └── test/               # Root module for test-style deployment
└── test/                   # Extra standalone Terraform examples
```

## Prerequisites

- Terraform `>= 1.9.0`
- `hashicorp/azurerm` provider `~> 4.0`
- `hashicorp/random` provider `~> 3.6`
- Azure subscription access with permission to create network, identity, compute, and data resources

## Simple steps to use

1. Go to the environment you want to deploy.

```bash
cd environment/dev
# or
cd environment/test
```

2. Set your Azure subscription in `provider.tf` (`subscription_id = "..."`).
3. Update values in `terraform.tfvars` for your naming, region, and module inputs.
4. Run Terraform commands.

```bash
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

5. To remove resources later:

```bash
terraform destroy -auto-approve
```

## How this code is organized

- `environment/dev/main.tf` and `environment/test/main.tf` are composition layers that call modules from `../../modules/*`.
- Most modules are built for reusability with maps and `for_each`.
- Module inputs are defined in each module `variables.tf`.
- Module outputs are exposed from each module `output.tf`/`outputs.tf`.
- Each module has its own local guide file (except where noted below).

## Modules and what they create

| Module | Main resources in code | Module guide |
| --- | --- | --- |
| `AKS-Cluster` | `azurerm_kubernetes_cluster`, `azurerm_kubernetes_cluster_node_pool`, `azurerm_role_assignment` | [AKS-Guide.md](modules/AKS-Cluster/AKS-Guide.md) |
| `App-Gateway` | `azurerm_application_gateway`, `azurerm_web_application_firewall_policy`, `azurerm_public_ip`, `azurerm_user_assigned_identity` | [MODULE-GUIDE.md](modules/App-Gateway/MODULE-GUIDE.md) |
| `Azure-Container-Registries` | `azurerm_container_registry` | [Acr-module-guide.md](modules/Azure-Container-Registries/Acr-module-guide.md) |
| `Azure-Firewall` | `azurerm_firewall`, `azurerm_firewall_policy`, firewall policy rule collection groups | [azurefirewall-module-guide.md](modules/Azure-Firewall/azurefirewall-module-guide.md) |
| `Azure-Frontdoor` | `azurerm_cdn_frontdoor_profile`, endpoint, origin group, origin, route | [MODULE-GUIDE.md](modules/Azure-Frontdoor/MODULE-GUIDE.md) |
| `Diagnostic-Settings` | `azurerm_monitor_diagnostic_setting` | [Azure-Diagnostic-settings-Guide.md](modules/Diagnostic-Settings/Azure-Diagnostic-settings-Guide.md) |
| `Disk-Encryption-Set` | `azurerm_disk_encryption_set` | No separate guide file |
| `Key-Vaults` | `azurerm_key_vault` | [KEY-VAULT-MODULE-GUIDE.md](modules/Key-Vaults/KEY-VAULT-MODULE-GUIDE.md) |
| `Linux-VM` | `azurerm_linux_virtual_machine`, NIC, NSG, optional public IP | [module-guide.md](modules/Linux-VM/module-guide.md) |
| `Log-Analytics-Workspace` | `azurerm_log_analytics_workspace` | [MODULE-GUIDE.md](modules/Log-Analytics-Workspace/MODULE-GUIDE.md) |
| `PostgreSQL` | `azurerm_postgresql_flexible_server`, server configurations | [MODULE-GUIDE.md](modules/PostgreSQL/MODULE-GUIDE.md) |
| `Private-DNS-Zone` | `azurerm_private_dns_zone`, VNet links | [MODULE-GUIDE.md](modules/Private-DNS-Zone/MODULE-GUIDE.md) |
| `Private-Endpoints` | `azurerm_private_endpoint` | [MODULE-GUIDE.md](modules/Private-Endpoints/MODULE-GUIDE.md) |
| `RG` | `azurerm_resource_group` | [RG-MODULE-GUIDE.md](modules/RG/RG-MODULE-GUIDE.md) |
| `Role-Assignment` | `azurerm_role_assignment` | [MODULE-GUIDE.md](modules/Role-Assignment/MODULE-GUIDE.md) |
| `Route-Table` | `azurerm_route_table`, `azurerm_route`, subnet association | No separate guide file |
| `Storage-Accounts` | `azurerm_storage_account` | [STORAGE-MODULE-GUIDE.md](modules/Storage-Accounts/STORAGE-MODULE-GUIDE.md) |
| `User-Assigned-Identity` | `azurerm_user_assigned_identity`, optional role assignment | [MODULE-GUIDE.md](modules/User-Assigned-Identity/MODULE-GUIDE.md) |
| `Vnet` | `azurerm_virtual_network`, subnets, optional DDoS plan | [MODULE-GUIDE.md](modules/Vnet/MODULE-GUIDE.md) |
| `Vnet-Peering` | `azurerm_virtual_network_peering` (both directions) | [MODULE-GUIDE.md](modules/Vnet-Peering/MODULE-GUIDE.md) |

## Notes

- `environment/dev` focuses on end-to-end stack composition with CMK, identities, AKS, private endpoints, and routing.
- `environment/test` includes hub-spoke VNet peering and PostgreSQL private networking examples.
- `test/` folder has standalone Terraform examples for specific scenarios.

## Recommended workflow for changes

1. Update a module in `modules/<module-name>/`.
2. Validate that module in a root environment (`environment/dev` or `environment/test`).
3. Run `terraform plan` before applying.
4. Keep secrets out of version control (for example: database passwords in `terraform.tfvars`).
