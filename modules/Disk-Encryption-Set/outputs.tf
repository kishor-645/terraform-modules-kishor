output "id" {
  value = azurerm_disk_encryption_set.this.id
}

output "principal_id" {
  # Useful if you used SystemAssigned and need to grant it KV access
  value = azurerm_disk_encryption_set.this.identity[0].principal_id
}