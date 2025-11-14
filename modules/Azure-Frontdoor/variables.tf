variable "profile_name" {
  type        = string
  description = "The name of the Front Door profile"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "sku_name" {
  type        = string
  description = "The SKU of the Front Door profile"
}

variable "endpoint_name" {
  type        = string
  description = "The name of the Front Door endpoint"
}

variable "origin_group_name" {
  type        = string
  description = "The name of the Front Door origin group"
}

variable "origin_name" {
  type        = string
  description = "The name of the Front Door origin"
}

variable "origin_enabled" {
  type = bool
  description = "Enable or disable the origin"
}

variable "certificate_name_check_enabled" {
  type = bool
  description = "Enable or disable certificate name check"
}

variable "origin_host_name" {
  type        = string
  description = "The hostname of the origin"
}

variable "origin_http_port" {
  type        = number
  description = "The HTTP port of the origin"
}

variable "origin_https_port" {
  type        = number
  description = "The HTTPS port of the origin"
}

variable "origin_priority" {
  type        = number
  description = "The priority of the origin"
}

variable "origin_weight" {
  type        = number
  description = "The weight of the origin"
}

variable "session_affinity_enabled" {
  type        = bool
  description = "Enable or disable session affinity"
}

variable "restore_time_minutes" {
  type        = number
  description = "Time to restore traffic to healed endpoint"
}

variable "health_probe_interval" {
  type        = number
  description = "Interval in seconds for health probe"
}

variable "health_probe_path" {
  type        = string
  description = "Path for health probe"
}

variable "health_probe_protocol" {
  type        = string
  description = "Protocol for health probe"
}

variable "health_probe_request_type" {
  type        = string
  description = "Request type for health probe"
}

variable "additional_latency_ms" {
  type        = number
  description = "Additional latency in milliseconds for load balancing"
}

variable "sample_size" {
  type        = number
  description = "Sample size for load balancing"
}

variable "successful_samples_required" {
  type        = number
  description = "Successful samples required for load balancing"
}

variable "route_name" {
  type        = string
  description = "The name of the Front Door route"
}

variable "route_enabled" {
  type = bool
  description = "Enable or disable the route"
}

variable "supported_protocols" {
  type        = list(string)
  description = "List of supported protocols"
}

variable "patterns_to_match" {
  type        = list(string)
  description = "List of patterns to match"
}

variable "forwarding_protocol" {
  type        = string
  description = "Forwarding protocol"
}

variable "link_to_default_domain" {
  type        = bool
  description = "Link to default domain"
}

variable "https_redirect_enabled" {
  type        = bool
  description = "Enable HTTPS redirect"
}

# variable "tags" {
#   type        = map(string)
#   description = "Tags to assign to resources"
# }
