terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateshortlytics"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate" # <-- État de la DEV
  }
}