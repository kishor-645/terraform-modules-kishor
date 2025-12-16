variable "resource_group_name" {
  description = "RG where DNS Zones will be created"
  type        = string
}

variable "dns_zone_names" {
  description = "List of DNS Zones to create (e.g. ['privatelink.blob.core.windows.net', 'privatelink.vault...'])"
  type        = list(string)
}

variable "vnet_ids_to_link" {
  description = "Map of VNet Names to IDs to link these zones to"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}