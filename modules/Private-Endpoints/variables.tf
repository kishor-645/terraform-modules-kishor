variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "private_endpoints" {
  description = "Map of Private Endpoints to create."
  type = map(object({
    subnet_id                      = string
    private_connection_resource_id = string
    subresource_names              = list(string) # e.g. ["blob"], ["vault"]
    private_dns_zone_ids           = list(string)
  }))
}