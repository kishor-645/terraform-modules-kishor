resource "azurerm_cdn_frontdoor_origin_group" "AFD_origin_group" {
  name                     = var.origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.AFD_profile.id
  session_affinity_enabled = var.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = var.restore_time_minutes

  health_probe {
    interval_in_seconds = var.health_probe_interval
    path                = var.health_probe_path
    protocol            = var.health_probe_protocol
    request_type        = var.health_probe_request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = var.additional_latency_ms
    sample_size                        = var.sample_size
    successful_samples_required        = var.successful_samples_required
  }
}