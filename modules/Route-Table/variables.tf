variable "name" {
  description = "The name of the Route Table."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "bgp_route_propagation_enabled" {
  description = "Boolean to disable BGP route propagation."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  # FIX: Change type to map so keys are known at plan time
  description = "A map of Subnet Name to Subnet ID associations."
  type        = map(string)
  default     = {}
}

variable "routes" {
  description = "A map of route objects."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}

  # Validation ensures users don't type invalid next hop types
  validation {
    condition = alltrue([
      for r in var.routes : contains([
        "VirtualNetworkGateway", 
        "VnetLocal", 
        "Internet", 
        "VirtualAppliance", 
        "None"
      ], r.next_hop_type)
    ])
    error_message = "next_hop_type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None."
  }
}

variable "tags" {
  description = "Tags map."
  type        = map(string)
  default     = {}
}