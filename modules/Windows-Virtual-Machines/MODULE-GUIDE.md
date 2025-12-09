Windows Virtual Machines Module Guide

Purpose
- Create Windows VMs with required network interfaces, NSGs, public IPs (optional), and provisioning via WinRM/Custom Script Extensions.

Inputs
- `resource_group_name`, `location`
- `windows_vms` map: `name`, `size`, `image`, `admin_username`, `admin_password` (use Key Vault), `subnet_id`, `public_ip`.

Outputs
- `windows_vms` map with `id`, `private_ip`, `public_ip` (if created).

Basic example
```hcl
module "windows_vms" {
  source = "../../modules/Windows-Virtual-Machines"
  resource_group_name = "rg-app"
  windows_vms = {
    "winapp01" = { vm_size = "Standard_DS2_v2", image = "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest", admin_username = "AdminUser", admin_password = var.admin_password, subnet_id = var.subnet_id }
  }
}
```

Notes
- Store `admin_password` in Key Vault and reference via `azurerm_key_vault_secret` or other secure mechanism.
- Configure NSG rules to allow management traffic (RDP) only from allowed IP ranges.
