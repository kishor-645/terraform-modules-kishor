output "firewall_id" {
  description = "Firewall ID"
  value       = azurerm_firewall.firewall.id
}

output "firewall_name" {
  description = "Firewall name"
  value       = azurerm_firewall.firewall.name
}

output "firewall_private_ip" {
  description = "Firewall private IP address"
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "Firewall policy ID"
  value       = azurerm_firewall_policy.policy.id
}

output "firewall_policy_name" {
  description = "Firewall policy name"
  value       = azurerm_firewall_policy.policy.name
}
