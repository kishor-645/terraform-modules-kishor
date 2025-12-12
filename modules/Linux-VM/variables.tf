variable "vm_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }

variable "vm_size" {
  description = "The size of the Virtual Machine (e.g., Standard_B2ms, Standard_D2s_v5)"
  type        = string
  default     = "Standard_B2ms"
}

variable "image_key" {
  description = "OS Image to use. Options: ubuntu20, ubuntu22, ubuntu24, rhel8"
  type        = string
  default     = "ubuntu22"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "admin_password" {
  description = "Password for the VM. Required if ssh_public_key is null."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH Public Key. If provided, disables password auth by default."
  type        = string
  default     = null
}

variable "disk_type" {
  description = "Disk type: Standard_LRS, StandardSSD_LRS, Premium_LRS"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "enable_public_ip" {
  description = "Create a Public IP for this VM?"
  type        = bool
  default     = false
}

variable "zone" {
  description = "Availability Zone (e.g. '1', '2'). Leave null for no zone."
  type        = string
  default     = null
}

variable "nsg_rules" {
  description = "List of specific Security Rules for this VM"
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
  default = []
}