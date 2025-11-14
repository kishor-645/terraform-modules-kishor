# Public IP for Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  resource_group_name = "rg-network"
  location            = "eastus"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Firewall Subnet
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "rg-network"
  virtual_network_name = "vnet-prod"
  address_prefixes     = ["10.0.1.0/26"]
}

# Azure Firewall Module
module "azure_firewall" {
  source = "./tf-modules/modules/Azure-Firewall"

  resource_group_name  = "rg-firewall-prod"
  location             = "eastus"
  firewall_name        = "fw-prod"
  firewall_policy_name = "fw-policy-prod"
  firewall_sku_tier    = "Standard"
  zones                = ["1", "2", "3"]

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  dns_proxy_enabled = true
  dns_servers       = ["168.63.129.16"]

  # Application Rules
  application_rules = [
    {
      name              = "allow-microsoft-services"
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.microsoft.com", "*.windows.net"]
      protocol_type     = "Https"
      protocol_port     = 443
    }
  ]

  # Network Rules
  network_rules = [
    {
      name                  = "allow-web"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }
  ]

  # NAT Rules
  nat_rules = [
    {
      name                = "ssh-jumpbox"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["2222"]
      translated_address  = "10.0.1.10"
      translated_port     = 22
    }
  ]
}

# Outputs
output "firewall_private_ip" {
  value = module.azure_firewall.firewall_private_ip
}