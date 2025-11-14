## Modules update suggestions — ASK-style audit

Date: 2025-11-14

Purpose
-------
This single document gives a non-invasive, prioritized set of suggestions for updating the Terraform modules found in `modules/` (list provided by you). I did not modify any code. Instead this file shows what to check and where to change things to make the code compatible with a modern, stable Terraform + AzureRM provider setup and to simplify maintenance for production.

Assumptions (please confirm)
--------------------------------
- Target Terraform: 1.x series (recommend >= 1.5 or latest stable 1.x). I assume you want to stay on the current Terraform stable major rather than v0.x compatibility.
- Target AzureRM provider: upgrade to the latest stable v3/v4+ available for your organization (pin explicitly in `required_providers`). I do not change code here — the exact version should be chosen after a single `terraform init -upgrade` smoke-test in a sandbox.
- You want minimal, low-risk changes first (pin providers, run init/upgrade, fix critical deprecated blocks). Larger refactors (behavior changes, switching to Azure RBAC for Key Vault) are listed as higher-effort and flagged as such.

How to use this document
-------------------------
1. Read the high-level checklist and recommended commands (section below). These are safe to run in a sandbox or feature branch.
2. For each module below, follow the file pointers to inspect the block(s) mentioned and apply the recommended change. I mark each suggestion with a severity tag (Critical / High / Medium / Low) and an effort estimate.
3. Run `terraform init -upgrade` and `terraform validate` after provider/version changes, then run targeted `terraform plan` for each module (or the whole workspace with a test backend).

Quick checklist (apply this first)
----------------------------------
- Add or update a root-level `versions.tf` (or equivalent) with:
  - `required_version` constraint for Terraform (e.g. `>= 1.5.0` — confirm your desired baseline).
  - `required_providers` pin for `azurerm` (and any other provider used, e.g., `random`, `tls`, `azuread`): pin to a stable minor/patch range.
  - Example minimal snippet (edit to pick your exact versions):

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 5.0.0" # choose exact range after testing
    }
  }
}
```

- Enable provider `features {}` block in root provider config if not present (modern azurerm requires an explicit `features {}` block even if empty).
- Add/refresh `terraform.lock.hcl` by running `terraform init -upgrade` (in a safe branch). Commit the lockfile.

Sanity-run commands (in a sandbox branch/backed test subscription)
---------------------------------------------------------------
1. terraform init -upgrade
2. terraform validate
3. terraform plan (module by module or a small test workspace)

If anything fails, inspect the specific resource block reported and follow the per-module notes below.

Per-module analysis and recommendations
---------------------------------------
Files are referenced relative to the workspace `modules/` folder. The suggestions are ordered by likely impact.

1) AKS-Private-Cluster (folder: `AKS-Private-Cluster/`)
   Files: `aks.tf`, `data.tf`, `output.tf`, `private_DNS_Zone.tf`, `role_assignment.tf`, `variables.tf`

   What to check / likely updates:
   - Critical: Ensure `azurerm_kubernetes_cluster` resource syntax matches your targeted azurerm provider version. Newer provider versions sometimes introduced separate node pool resource `azurerm_kubernetes_cluster_node_pool` or changed arguments; inspect `aks.tf` for inline `agent_pool_profile` usage and consider migrating to explicit node pool resources if provider shows deprecation warnings.
   - High: Confirm use of `rbac` and `role_assignment` blocks in `role_assignment.tf`. New provider versions emphasize managed identities and role assignment blocks may require `principal_id` or `principal_oid` changes. Verify `depends_on` usage for role assignments to avoid race conditions during create.
   - Medium: Private DNS zones and Azure Private Link integrations may have slightly different data-source names or required attributes. Check `private_DNS_Zone.tf` for `azurerm_private_dns_zone` usage and any `virtual_network_link` patterns.
   - Low: Simplify variables where possible (e.g., merge booleans or redundant outputs). Keep the module interface minimal for production.

   Files to inspect/lines likely to change: `aks.tf` (cluster & node pools), `role_assignment.tf` (role assignment resource blocks)

2) App-Gateway (folder: `App-Gateway/`)
   Files: `app_gateway.tf`, `data.tf`, `kv_access_policy.tf`, `managed_identity.tf`, `output.tf`, `public_ip.tf`, `variables.tf`, `waf_policy.tf`

   What to check / likely updates:
   - Critical: Application Gateway resource names/arguments may have changed; confirm `azurerm_application_gateway` block parameters (frontend_port, frontend_ip_configuration, ssl_certificate references). If WAF policy integration uses older attributes, migrate to the new `waf_policy_link` or resource names.
   - High: Key Vault access policies (`kv_access_policy.tf`) — in many modern setups `access_policy` blocks are deprecated in favor of separate `azurerm_key_vault_access_policy` resources or Azure RBAC. Consider migrating to `azurerm_key_vault_access_policy` or (preferably) Azure RBAC for production (more secure, less brittle). This is an important security-related migration.
   - Medium: `managed_identity.tf` — prefer using `azurerm_user_assigned_identity` (and pin attributes) and ensure compatibility with new principal id attributes.

   Files to inspect: `kv_access_policy.tf`, `waf_policy.tf`, `app_gateway.tf`, `managed_identity.tf`

3) Key-Vaults (folder: `Key-Vaults/`)
   Files: `access_policy.tf`, `key_vault.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - Critical: As above, migrate `access_policy` blocks. For production, prefer Azure RBAC or `azurerm_key_vault_access_policy`. This reduces future breakage and is generally recommended by Microsoft.
   - High: Ensure `soft_delete_enabled`, `purge_protection_enabled`, `default_action` on network_acls and other security hardening flags are present and set to production-safe values.

   Files to inspect: `access_policy.tf`, `key_vault.tf`

4) Azure-Container-Registries (folder: `Azure-Container-Registries/`)
   Files: `acr.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - Medium: Ensure `admin_enabled = false` for production. Confirm `sku` usage, `network_rule_set` block names, and `georeplication` patterns if used.
   - Low: Consider enabling `policy` or `retention` settings and immutable storage where appropriate.

   Files to inspect: `acr.tf`

5) Azure-Firewall (folder: `Azure-Firewall/`)
   Files: `application_rules.tf`, `firewall_policy.tf`, `firewall.tf`, `nat_rules.tf`, `network_rules.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - High: Firewall and firewall policy resource schema sometimes changes across major provider updates—validate `azurerm_firewall`, `azurerm_firewall_policy` and rule collections for strict typing.
   - Medium: Ensure public IPs and SKU definitions align with new provider expectations.

   Files to inspect: `firewall_policy.tf`, `application_rules.tf`, `network_rules.tf`

6) Azure-Frontdoor (folder: `Azure-Frontdoor/`)
   Files: `ADF_profile.tf`, `AFD_endpoint.tf`, `AFD_origin_group.tf`, `AFD_origin.tf`, `AFD_route.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - Medium: Azure Front Door v2 resources have been renamed in some provider versions. Check for `azurerm_frontdoor`, `azurerm_frontdoor_endpoint`, `azurerm_frontdoor_origin` naming — update to current names if provider reports deprecation.
   - Low: Confirm WAF integration blocks and routing rules are valid.

   Files to inspect: all `AFD_*.tf` files

7) Azure-Private-Endpoints (folder: `Azure-Private-Endpoints/`)
   Files: `private_endpoint.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - High: Private endpoint connections often require exact `subresource_names` and `group_id` values that provider updates may have changed for certain services. Verify `azurerm_private_endpoint` attributes.

   Files to inspect: `private_endpoint.tf`

8) Linux-Virtual-Machines & Windows-Virtual-Machines (folders: `Linux-Virtual-Machines/`, `Windows-Virtual-Machines/`)
   Files: `nic.tf`, `nsg.tf`, `output.tf`, `public_ip.tf`, `variables.tf`, `vms.tf`

   What to check / likely updates:
   - Medium: VM resource (`azurerm_linux_virtual_machine`, `azurerm_windows_virtual_machine`) API was introduced to replace older `azurerm_virtual_machine` in newer providers. If your modules still use the old unified resource, consider migrating (this can be higher effort).
   - Medium: NIC and NSG blocks may have changed argument names (e.g., `security_rule` schema). Validate by running `terraform plan` after provider update.

   Files to inspect: `vms.tf` files and `nic.tf`, `nsg.tf`

9) PostgreSQL-Flexible-Server (folder: `PostgreSQL-Flexible-Server/`)
   Files: `main.tf`, `output.tf`, `variables.tf`

   What to check / likely updates:
   - High: Flexible Server resource arguments evolved (backup, high availability, zone redundancy). Validate `azurerm_postgresql_flexible_server` attributes and recommended versions.

   Files to inspect: `main.tf`

10) Private-DNS-Zone, RG, Storage-Accounts, Vnet, Vnet-peering
    Files: various under each folder

    What to check / likely updates:
    - Low/Medium: These foundational resources (`azurerm_resource_group`, `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_storage_account`, `azurerm_private_dns_zone`, `azurerm_virtual_network_peering`) are generally stable, but check for:
      - renamed arguments (rare) and deprecations
      - storage account `allow_nested_items` or `is_hns_enabled` usage if using Data Lake features
    - Ensure `network_security_group` and `subnet` references use the correct `id`/`name` attributes in new provider versions.

Risk and priority guidance
--------------------------
- Critical: Provider pinning + `features {}` + KeyVault access policy migration + AKS node pool changes. These can block plans or create security issues.
- High: Firewall, PostgreSQL Flexible Server, Private Endpoints, and any resource where provider changed major schema.
- Medium: ACR, App Gateway settings, VM types migration to the `*_virtual_machine` resources.
- Low: Cosmetic simplifications, outputs/variable cleanup, small refactors.

Simple change philosophy
-------------------------
- Prefer small, localized edits that adapt resource blocks to the newer provider schema rather than complete rewrites.
- Keep module inputs/outputs stable: if you change a variable name, add a compatibility alias or keep the old name and map it to the new one for one release cycle.
- Prefer enabling production-safe defaults (secure by default) and small opt-outs via variables (e.g., allow `enable_admin_user` only when explicitly set).

Example targeted edits (non-invasive examples you can apply)
-----------------------------------------------------------
- Add root `versions.tf` to pin providers and terraform version (see snippet earlier).
- Replace inline `access_policy` blocks in `Key-Vaults/key_vault.tf` with separate `azurerm_key_vault_access_policy` resources, or plan to adopt Azure RBAC.
- For AKS in `AKS-Private-Cluster/aks.tf`, if you see `agent_pool_profile` blocks, plan to migrate to `azurerm_kubernetes_cluster_node_pool` in a controlled rollout (create new node pools, cordon and drain old nodes if necessary) — or update the block syntax to match provider docs.

Edge cases & gotchas
---------------------
- Locked provider versions: If you have an existing `terraform.lock.hcl` that pins an older azurerm plugin, `terraform init -upgrade` is required to get the newer plugin. Test in a branch first.
- Backend state compatibility: Upgrading provider or Terraform may change resource schema; keep a state backup and test in non-prod subscription.
- Azure API changes: Sometimes Azure service APIs change independently of the provider; provider releases will surface these as new attributes — always consult the provider release notes.

Next steps I recommend (safe minimal path)
-----------------------------------------
1. Create a feature branch.
2. Add/update `versions.tf` with a conservative provider range and `features {}`. Commit.
3. Run `terraform init -upgrade` locally for the workspace and resolve any immediate provider-install issues.
4. Run `terraform validate` and `terraform plan` for a single small module (start with `RG` or `Vnet`) to validate provider changes.
5. Tackle Critical items in a separate PR each: Key Vault access policy migration, AKS node pool adjustments.

Useful dev commands (run in a sandbox, not against production state without testing)
----------------------------------------------------------------------------------
```bash
# create/checkout feature branch
git checkout -b upgrade/azurerm-1

# init and upgrade provider plugins
terraform init -upgrade

# validate and plan (module-level or full workspace)
terraform validate
terraform plan -out=tfplan
terraform show -json tfplan | jq '.' # optional inspection
```

Files & modules covered in this audit
-------------------------------------
- AKS-Private-Cluster/
- App-Gateway/
- Azure-Container-Registries/
- Azure-Firewall/
- Azure-Frontdoor/
- Azure-Private-Endpoints/
- Key-Vaults/
- Linux-Virtual-Machines/
- PostgreSQL-Flexible-Server/
- Private-DNS-Zone/
- RG/
- Storage-Accounts/
- Vnet/
- Vnet-peering/
- Windows-Virtual-Machines/

Final notes and offer
---------------------
I intentionally kept the document actionable and conservative. If you want, I can now:

- Option A (recommended): Create a `versions.tf` file in the repo and run `terraform init -upgrade` in a sandbox branch, capture any errors, and produce a follow-up patch that updates just the exact resource blocks that fail (I will open a PR-style patch but will not change production files unless you say so).
- Option B: Generate a per-module checklist with precise line-level suggestions after I read the actual contents of a module file (I avoided reading files on this pass as requested, but I can inspect them next if you want exact code edits).

Which option do you prefer? If Option A, I will create the `versions.tf` and run `terraform init -upgrade` in a branch and report the errors and exact edits required.

— End of report
