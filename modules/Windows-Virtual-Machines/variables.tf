variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type = string
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "vm_admin_password" {
  description = "Admin password for the VM"
  type        = string
}

variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "vm_type" {
  description = "The type of the VM (Linux or Windows)"
  type        = string
}

variable "subnet_id" {
  description = "subnet ID"
  type = string
}

# NSG

variable "security_rules" {
  description = "List of security rules to apply to the NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}