resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-rg"
  location = var.location
}

data "azurerm_client_config" "current" {}

module "network" {
  source         = "../../modules/network"
  resource_group = azurerm_resource_group.main.name
  location       = azurerm_resource_group.main.location
  project_prefix = var.project_prefix
}

# 2. Compute Module (AKS + OIDC)
module "compute" {
  source         = "../../modules/compute"
  resource_group = azurerm_resource_group.main.name
  location       = azurerm_resource_group.main.location
  project_prefix = var.project_prefix
  subnet_id      = module.network.aks_subnet_id
}

# 3. Security & Identity Module (ACR, Key Vault, Workload Identity & Role Assignments)
module "security" {
  source                                    = "../../modules/security"
  resource_group                            = azurerm_resource_group.main.name
  location                                  = azurerm_resource_group.main.location
  project_prefix                            = var.project_prefix
  tenant_id                                 = data.azurerm_client_config.current.tenant_id
  aks_oidc_issuer_url                       = module.compute.oidc_issuer_url
  aks_kubelet_identity_object_id            = module.compute.kubelet_identity_object_id
  aks_key_vault_secrets_provider_object_id = module.compute.key_vault_secrets_provider_object_id
}