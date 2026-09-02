variable "resource_group" {}
variable "location" {}
variable "project_prefix" {}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Private DNS Zone (e.g. shortlytics-dev.internal)
resource "azurerm_private_dns_zone" "internal" {
  name                = "${var.project_prefix}.internal"
  resource_group_name = var.resource_group
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.project_prefix}-dns-vnet-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks_subnet.id
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.internal.id
}

output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.internal.name
}