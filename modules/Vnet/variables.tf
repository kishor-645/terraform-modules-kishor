variable "vnets" {
  description = "A map of VNET configurations"
  type = map(object({
    name                   = string
    address_space          = list(string)
    enable_ddos_protection = bool
    subnets = map(object({
      name           = string
      address_prefix = string
      
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(list(string))
        })
      }), null)
    }))
  }))
}

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "location" {
  description = "Name of the location"
}