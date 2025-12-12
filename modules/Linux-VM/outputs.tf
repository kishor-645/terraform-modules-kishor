output "vm_id" {
  description = "The Resource ID of the Linux VM"
  value       = azurerm_linux_virtual_machine.this.id
}

output "private_ip" {
  description = "The Private IP Address"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip" {
  description = "The Public IP Address (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : "No Public IP"
}

output "principal_id" {
  description = "The System Assigned Identity Principal ID"
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}