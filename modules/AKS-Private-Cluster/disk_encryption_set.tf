locals {
  create_des = var.cmk_enabled && length(trim(var.cmk_key_vault_key_id)) > 0
}

resource "azurerm_disk_encryption_set" "aks_des" {
  count               = local.create_des ? 1 : 0
  name                = "${var.aks_cluster_name}-des"
  location            = var.location
  resource_group_name = var.resource_group_name

  key_vault_key_id = var.cmk_key_vault_key_id

  identity {
    type = length(trim(var.des_identity_id)) > 0 ? "UserAssigned" : "SystemAssigned"
  }
}

output "disk_encryption_set_id" {
  value = local.create_des ? azurerm_disk_encryption_set.aks_des[0].id : ""
}
