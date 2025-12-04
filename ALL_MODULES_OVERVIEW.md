# Terraform Modules - Overview

This document lists the modules in `modules/` with a short description, how dynamic/configurable they are, main features, typical integrations and the primary files to inspect. Use this as a quick reference when planning upgrades, integrations or auditing.

> Note: dynamicity indicates how configurable the module appears (High = many variables/inputs or multiple tf files; Medium = some inputs; Low = mostly static).

## Module Summary Table

| Module | Description | Dynamicity | Key Features | Integrations | Key files |
|---|---|---:|---|---|---|
| AKS-Private-Cluster | Deploys an AKS private cluster with node pools and role assignments. Likely supports private networking and role bindings. | High | AKS cluster, node pools, private cluster options, role assignment | ACR, Key Vault, Log Analytics, Azure AD, RBAC | `aks.tf`, `role_assignment.tf`, `variables.tf` |
| App-Gateway | Application Gateway with WAF, public IPs, managed identity, and Key Vault access policy support. | High | WAF policies, listener/backend routing, public IP, managed identity, KeyVault cert access | Key Vault (certs), Azure Firewall, Backend pools (VMs/AKS), Log Analytics | `app_gateway.tf`, `waf_policy.tf`, `public_ip.tf`, `managed_identity.tf`, `kv_access_policy.tf` |
| Azure-Container-Registries | Creates ACR with outputs and variables; includes guidance via `Acr-module-guide.md`. | Medium | ACR registry, role assignments, possibly network rules | AKS, CI/CD, Private Endpoints, Key Vault | `acr.tf`, `variables.tf`, `output.tf` |
| Azure-Firewall | Builds Azure Firewall with policy, nat/network/application rules and outputs. Supports premium features if configured. | High | Firewall policy, NAT rules, network rules, application rules, main firewall resource | Route Tables (UDR), Public IP, Log Analytics, Private Endpoint integration | `main.tf`, `firewall_policy.tf`, `nat_rules.tf`, `application_rules.tf`, `network_rules.tf` |
| Azure-Frontdoor | Front Door (AFD) resources: profiles, endpoints, origins, origin groups and routes. | High | Global routing, origin groups, custom domains, route configuration | Backend origins (App Gateway, Storage, ACR), WAF, CDN | `AFD_profile.tf`, `AFD_endpoint.tf`, `AFD_origin_group.tf`, `AFD_origin.tf`, `AFD_route.tf` |
| Azure-Private-Endpoints | Generic private endpoint resources for integrating platform services privately into VNets. | Medium | Private endpoint creation, DNS and NIC configuration | Storage Accounts, Key Vault, SQL, ACR, Log Analytics | `private_endpoint.tf`, `variables.tf`, `output.tf` |
| Diagnostic-Settings | Centralized diagnostic settings to send resource logs/metrics to Log Analytics, Event Hub or Storage. | Medium | Diagnostic settings, category selection, destinations (LA/Storage/EventHub) | Log Analytics Workspace, Event Hub, Storage Account | `diagnostic_settings.tf`, `variables.tf` |
| Key-Vaults | Deploy Key Vaults with access policies. Likely supports access policies and RBAC patterns. CMK/HSM notes exist in repo-level status. | Medium | Key Vault creation, access policies, output secrets references | Managed Identities, VMs, AKS, Storage encryption (CMK), HSM/Key Vault for CMK | `key_vault.tf`, `access_policy.tf`, `variables.tf` |
| Linux-Virtual-Machines | VM module split across NIC, NSG and VM resources (Linux-specific). | Medium | vNIC, NSG, public IP (optional), VM provisioning, extensions | Key Vault (secrets), Log Analytics, Availability Sets/Disks | `vms.tf`, `nic.tf`, `nsg.tf`, `public_ip.tf` |
| Windows-Virtual-Machines | Same as Linux but windows images and extensions. | Medium | vNIC, NSG, public IP (optional), VM provisioning, extensions | Key Vault, Log Analytics, Auto-Update/Extensions | `vms.tf`, `nic.tf`, `nsg.tf`, `public_ip.tf` |
| Log-Analytics-Workspace | Creates central Log Analytics Workspace used for diagnostics and monitoring/alerts. | Medium | LA Workspace creation, retention, linked services | Diagnostic Settings, Azure Monitor, Sentinel, Firewall, AKS | `log_analytics.tf`, `variables.tf`, `output.tf` |
| PostgreSQL-Flexible-Server | Deploys Azure Database for PostgreSQL Flexible Server with HA and CMK options (per notes). | Medium | Flexible server, HA options, backup/restore settings, CMK encryption hooks | VNet (private access), Key Vault (CMK), Monitoring | `main.tf`, `variables.tf`, `output.tf` |
| Private-DNS-Zone | Creates Private DNS zones and record sets for private endpoints / internal name resolution. | Medium | DNS zone creation, VNet links, records for endpoints | Private Endpoints, VNet, AKS, VMs | `main.tf`, `variable.tf`, `output.tf` |
| RG (Resource Groups) | Creates resource groups used across environments. Simple but fundamental. | Low | Resource Group creation, tags | All modules (used as target) | `RG.tf`, `variables.tf`, `output.tf` |
| Storage-Accounts | Builds Storage Accounts, with outputs and variables. Private endpoint and CMK notes exist in status. | Medium | Storage account options, network rules, encryption scopes | Private Endpoints, Key Vault (CMK), Diagnostic Settings | `storage_accounts.tf`, `variables.tf`, `output.tf` |
| Vnet | Hub and spoke VNet creation with subnets. Looks designed for hub+spoke topologies. | High | VNets, subnets, possible DDOS settings or service endpoints | Private Endpoints, Firewall, AKS, VMs, Private DNS | `main.tf`, `variables.tf`, `output.tf` |
| Vnet-peering | Implements peering between VNets (hub-spoke). | Low-Medium | Peering resources (connections, gateways if included) | Vnet module, route propagation, Firewall | `peering.tf`, `variables.tf`, `output.tf` |

---

## Improved Tracking Table (reference for status planning)

| Module | Purpose | Status | Notes | Dynamicity | Primary Resources | Integrations |
|---|---|---|---|---:|---|---|
| RG | Creates all Resource Groups | Done | Basic RG creation with tags | Low | `azurerm_resource_group` | All modules |
| Vnet | Virtual Network + Subnets (hub + spoke + optional DDOS) | Done | Hub+Spoke design; check for DDOS config in environment | High | `azurerm_virtual_network`, `azurerm_subnet` | Firewall, Private Endpoints, Private DNS |
| NSG | Network Security Groups / rules | ToDo | NSG resources exist in VM modules; a central module not present | Medium | `azurerm_network_security_group` | Subnets, NICs, VM modules |
| UDR (Route Tables) | Custom routes (to Firewall/Appliance) | ToDo / Missing | No dedicated UDR module found in `modules/` | Low | `azurerm_route_table`, `azurerm_route` | Firewall, Subnets, Route Propagation |
| Azure-Firewall | Azure Firewall Premium (policy, rules) | Done | Firewall module present with policies and rules | High | `azurerm_firewall`, `azurerm_firewall_policy` | RTs/UDR, Public IP, Log Analytics |
| Key Vaults | HSM / CMK keys, access policies | In-Progress | CMK/HSM usage noted as work in progress | Medium | `azurerm_key_vault`, `azurerm_key_vault_key` | Disk Encryption, Storage CMK, PostgreSQL CMK, VMs |
| AKS | AKS cluster + node pools (private) | Done | AKS private cluster module present | High | `azurerm_kubernetes_cluster`, node pools | ACR, Log Analytics, Key Vault, Azure AD |
| PostgreSQL | Flexible Server (CMK, HA) | Done | Module present; verify CMK enablement | Medium | `azurerm_postgresql_flexible_server` | VNet, Key Vault (CMK), Backups |
| Storage Account | Storage + private endpoint + encryption | In-Progress | CMK pending as per notes | Medium | `azurerm_storage_account` | Private Endpoints, Key Vault, Diagnostic Settings |
| Private Endpoints | Private endpoints for services | Done | Generic private endpoint module present | Medium | `azurerm_private_endpoint` | Storage, Key Vault, SQL, ACR |
| Monitoring | Log Analytics Workspace | In-Progress | Central LAW exists; diagnostic settings module available | Medium | `azurerm_log_analytics_workspace` | Diagnostic Settings, Alerts, Sentinel |
| Policies | Azure Policy Assignments | ToDo | No module found under `modules/` for policy assignments | Low | `azurerm_policy_assignment` | Management Group / Subscription |
| Log Alerts | Sentinel / Alert rules | ToDo | No dedicated alerting module found | Low | `azurerm_monitor_scheduled_query_rules`, `azurerm_monitor_metric_alert` | Log Analytics, Sentinel |
| Log Analytics workspace | Central LAW to store logs | Done | Present via `Log-Analytics-Workspace` module | Medium | `azurerm_log_analytics_workspace` | Diagnostics, Alerts, Sentinel |

---

## How to use this document

- Inspect each module's `variables.tf` and `outputs.tf` to understand configuration surface. Modules with `variables.tf` are typically more dynamic.
- If you need a dedicated NSG/UDR/Policy module, they appear to be missing and should be added as separate modules for reusability.
- For CMK/HSM enablement (Key Vault, PostgreSQL, Storage), validate Key Vault keys and identity access flows.

## Recommended next actions

- Add a central `network-security` module (NSGs) and `route-tables` (UDR) module if you want consistent network guardrails across subnets.
- Add a `policy-assignments` module to manage Azure Policies consistently across subscriptions.
- Verify the Key Vault module supports `soft-delete`, `purge_protection`, and Key Encryption Key creation for CMK scenarios.

---

## Appendix: Files to review per module

- `AKS-Private-Cluster/aks.tf`, `AKS-Private-Cluster/role_assignment.tf`
- `App-Gateway/app_gateway.tf`, `App-Gateway/waf_policy.tf`, `App-Gateway/kv_access_policy.tf`
- `Azure-Firewall/main.tf`, `Azure-Firewall/firewall_policy.tf`, `Azure-Firewall/nat_rules.tf`
- `Log-Analytics-Workspace/log_analytics.tf`
- `PostgreSQL-Flexible-Server/main.tf`

---

Generated: automatic summary for planning and audit. Update the tables as you confirm configurations after code review or running `terraform plan`.
