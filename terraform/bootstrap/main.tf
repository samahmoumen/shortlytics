resource "azurerm_resource_group" "tfstate" {
  name     = "terraform-state-rg"
  location = "polandcentral" 
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "tfstateshortlytics"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS" 
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = true # Crucial for state recovery
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}