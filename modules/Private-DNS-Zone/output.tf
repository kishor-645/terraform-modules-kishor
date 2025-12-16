output "dns_zone_ids" {
  description = "Map of DNS Zone Names to their Resource IDs"
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}