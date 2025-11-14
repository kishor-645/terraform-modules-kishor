data "azurerm_client_config" "current" {}

# Here I get the name of RG where our certificate is stored as a secret in KV.
# data "azurerm_resource_group" "rg_name" {
#   name = "searateserp"
# }


# data "azurerm_key_vault" "kv_name" {
#   name                = "searates-tech-keyvault"
#   resource_group_name = data.azurerm_resource_group.rg_name.name
# }

# data "azurerm_key_vault_secret" "kv_cert_secret_name1" {
#   name         = "searates-tech-crt8f03674d-f80f-4527-9110-230b892543e5"
#   key_vault_id = data.azurerm_key_vault.kv_name.id
# }

# #####################

# data "azurerm_key_vault" "kv_name1" {
#   name                = "searateserp-keyvault"
#   resource_group_name = data.azurerm_resource_group.rg_name.name
# }

# data "azurerm_key_vault_secret" "kv_cert_secret_name2" {
#   name         = "searateserp-wildcardb7737a0b-c256-451d-8787-036d5bf6f7d9"
#   key_vault_id = data.azurerm_key_vault.kv_name1.id
# }