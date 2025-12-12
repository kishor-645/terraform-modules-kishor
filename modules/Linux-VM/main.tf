locals {
  # Common Image Definitions for quick selection
  images = {
    "ubuntu20" = { publisher = "Canonical", offer = "0001-com-ubuntu-server-focal", sku = "20_04-lts-gen2", version = "latest" }
    "ubuntu22" = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2", version = "latest" }
    "ubuntu24" = { publisher = "Canonical", offer = "ubuntu-24_04-lts", sku = "server-gen1", version = "latest" }
    "rhel8"    = { publisher = "RedHat", offer = "RHEL", sku = "8-lvm-gen2", version = "latest" }
  }
  
  # Select the image based on the key provided in variables
  selected_image = local.images[var.image_key]
}

# --- 1. Public IP (Optional) ---
# Only created if enable_public_ip is true
resource "azurerm_public_ip" "this" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "pip-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zone != null ? [var.zone] : []
}

# --- 2. Network Security Group (Optional Rules) ---
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# --- 3. Network Interface ---
resource "azurerm_network_interface" "this" {
  name                = "nic-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # Attach Public IP if created, otherwise null
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.this[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# --- 4. Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "this" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]
  
  # Logic: If SSH key is provided, we prefer SSH but allow Password if strictly needed
  # If NO SSH key provided, this must be false to allow Password login.
  disable_password_authentication = var.ssh_public_key != null ? true : false
  encryption_at_host_enabled      = true
  zone                            = var.zone

  os_disk {
    name                 = "osdisk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = var.disk_type
  }

  source_image_reference {
    publisher = local.selected_image.publisher
    offer     = local.selected_image.offer
    sku       = local.selected_image.sku
    version   = local.selected_image.version
  }

  identity {
    type = "SystemAssigned"
  }

  # Dynamically add SSH key block only if a key string is provided
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }
}