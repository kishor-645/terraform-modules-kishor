### Usage Example (Root `main.tf`)

**Scenario 1: Private IP Only, SSH Key Auth**
```hcl
module "jumpbox_private" {
  source              = "./modules/Linux-VM"
  vm_name             = "vm-jumpbox-prod"
  resource_group_name = var.rg
  location            = var.location
  subnet_id           = module.vnet.subnets["mgmt"].id
  
  vm_size          = "Standard_B2ms"
  enable_public_ip = false
  image_key        = "ubuntu22"

  admin_username = "adminuser"
  # Password usually required by provider even with SSH, but ignored for login if SSH enabled
  admin_password = var.jumpbox_password 
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  nsg_rules = [] # No extra rules, relies on subnet NSG
}
```

**Scenario 2: Public IP, Password Auth**
```hcl
module "jumpbox_public" {
  source              = "./modules/Linux-VM"
  vm_name             = "vm-test-public"
  resource_group_name = var.rg
  location            = var.location
  subnet_id           = module.vnet.subnets["mgmt"].id
  
  vm_size          = "Standard_B2ms"
  enable_public_ip = true
  
  admin_username = "adminuser"
  admin_password = "ComplexPassword123!"
  ssh_public_key = null # Forces password auth to be enabled

  nsg_rules = [
    {
      name                       = "AllowSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "YOUR.HOME.IP/32"
      destination_address_prefix = "*"
    }
  ]
}
```