Linux Virtual Machines Module Guide

Purpose
- Create Linux VMs with NICs, NSG rules, public IPs (optional), and extensions for cloud-init or custom scripts.

Inputs
- `resource_group_name`, `location`
- `linux_vms` map: `name`, `vm_size`, `image`, `admin_username`, `ssh_key_data`, `subnet_id`, `public_ip` (bool)

Outputs
- `linux_vms` map with `id`, `private_ip`, `public_ip` (if created).

Basic example
```hcl
module "linux_vms" {
  source = "../../modules/Linux-Virtual-Machines"
  resource_group_name = "rg-app"
  linux_vms = {
    "app1" = { vm_size = "Standard_DS2_v2", image = "Canonical:UbuntuServer:20_04-lts:latest", admin_username = "adminuser", ssh_key_data = file("~/.ssh/id_rsa.pub"), subnet_id = var.subnet_id }
  }
}
```

Notes
- Use SSH keys for auth; avoid passwords in code.
- Use custom_data or extensions to bootstrap the VM.
- Ensure NSG rules open required ports only.
