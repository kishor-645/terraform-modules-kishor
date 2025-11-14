variable "pip_name" {
  description = "Public IP Name"
  type = string
}

variable "managed_identity_name" {
  description = "The name of the Managed Identity"
  type = string
}

variable "name" {
  description = "The name of the Application Gateway"
  type        = string
}

variable "location" {
  description = "The location of the Application Gateway"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "zones" {
  description = "Describe the zones of the Application Gateway"
  type = list(string)
}

variable "min_capacity" {
  description = "Autoscaling the minimum capacity"
  type = number
}

variable "max_capacity" {
  description = "Autoscaling the mix capacity"
  type = number
}


variable "sku_name" {
  description = "The SKU name of the Application Gateway"
  type        = string
}

variable "sku_tier" {
  description = "The SKU tier of the Application Gateway"
  type        = string
}

# variable "sku_capacity" {
#   description = "The capacity of the SKU"
#   type        = number
# }

variable "gateway_ip_configuration_name" {
  description = "The name of the gateway IP configuration"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}

variable "frontend_ports" {
  description = "List of frontend ports"
  type = list(object({
    name = string
    port = number
  }))
}

variable "frontend_ip_configurations" {
  description = "List of frontend IP configurations"
  type = list(object({
    name                 = string
    # public_ip_address_id = string
  }))
}

variable "backend_address_pools" {
  description = "Map of backend address pools"
  type = list(object({
    name       = string
    ip_addresses = list(string)
  }))
}

variable "backend_http_settings" {
  description = "List of backend HTTP settings"
  type = list(object({
    name                  = string
    cookie_based_affinity = string
    port                  = number
    protocol              = string
    request_timeout       = number
    probe_name = string
  }))
}

# variable "probe_name" {
#   description = "probe name in backend HTTP settings"
#   type = string
# }

variable "http_listeners" {
  description = "List of HTTP listeners"
  type = list(object({
    name                           = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_names                      = set(string)
  }))
}

variable "https_listeners" {
  description = "List of HTTP listeners"
  type = list(object({
    name                           = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_names                      = set(string)
    ssl_certificate_name            = string
  }))
}

variable "ssl_certificates" {
  description = "A list of SSL certificates with their names and Key Vault secret IDs."
  type = list(object({
    name                = string
    key_vault_secret_id = string
  }))
  # default = [ 
  #   {
  #     name                = "tech-cert"
  #     key_vault_secret_id = data.azurerm_key_vault_secret.kv_cert_secret_name1.id
  #   },
  #   {
  #     name                = "com-cert"
  #     key_vault_secret_id = data.azurerm_key_vault_secret.kv_cert_secret_name2.id
  #   }
  #  ]
}

variable "request_routing_rules" {
  description = "List of request routing rules"
  type = list(object({
    name                       = string
    http_listener_name         = string
    backend_address_pool_name  = string
    backend_http_settings_name = string
    priority                   = number
    redirect_configuration_name = string
  }))
}

variable "redirect_configurations" {
  type = list(object({
    name                 = string
    redirect_type        = string
    target_listener_name = string
    include_path         = bool
    include_query_string = bool
  }))
  default     = []
}


variable "probes" { 
  description = "List of probe"
  type = list(object({
    name                 = string
    host                  = string
    path                  = string
    protocol              = string
    interval              = number
    timeout               = number
    unhealthy_threshold   = number
    status_code = list(string)
    pick_host_name_from_backend_http_settings = bool
    }))
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# WAF Configurations

variable "waf_policy_name" {
  description = "Name of WAF Policy"
  type = string
}

# variable "firewall_mode" {
#   description = "The mode of the Web Application Firewall"
#   type        = string
#   default     = "Detection"
# }

# variable "rule_set_version" {
#   description = "The version of the OWASP rule set"
#   type        = string
#   default     = "3.2"
# }

# KV Access Policy

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "access_policies" {
  description = "List of access policies to be applied to the Key Vault."
  type = list(object({
    # object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
  }))
}
