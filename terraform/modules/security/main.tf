variable "resource_group" { type = string }
variable "location" { type = string }
variable "project_prefix" { type = string }
variable "tenant_id" { type = string }
variable "aks_oidc_issuer_url" { type = string }
variable "aks_kubelet_identity_object_id" { type = string }

variable "k8s_namespace" {
  type    = string
  default = "shortlytics-dev"
}

# --- THIS IS THE FIX ---
variable "k8s_service_account_name" {
  type    = string
  default = "shortlytics-dev-backend-backend-sa" 
}
# -----------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "backend-db-username"
  value        = "postgres"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_role_assignment.terraform_user_kv_officer
  ]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "backend-db-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_role_assignment.terraform_user_kv_officer
  ]
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.project_prefix, "-", "")}acr${random_string.suffix.result}"
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.project_prefix}-kv"
  location                    = var.location
  resource_group_name         = var.resource_group
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

# User-Assigned Identity for Workload Identity
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "${var.project_prefix}-workload-id"
  location            = var.location
  resource_group_name = var.resource_group
}

# Federated Credential linking Kubernetes ServiceAccount to Azure Managed Identity
resource "azurerm_federated_identity_credential" "workload_identity_fed" {
  name                = "${var.project_prefix}-fed-credential"
  resource_group_name = var.resource_group
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  subject             = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
}

# --- ROLE ASSIGNMENTS ---

# 1. Grant Key Vault Secrets User to Workload Identity
resource "azurerm_role_assignment" "workload_identity_kv_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

# 2. Grant AcrPull to AKS Kubelet Identity
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id = var.aks_kubelet_identity_object_id
}

output "acr_id" { value = azurerm_container_registry.acr.id }
output "key_vault_id" { value = azurerm_key_vault.kv.id }
output "acr_login_server" { value = azurerm_container_registry.acr.login_server }
output "key_vault_name" { value = azurerm_key_vault.kv.name }
output "workload_identity_client_id" {
  description = "Inject this client ID into your Helm values under global.azure.workloadIdentityClientId"
  value       = azurerm_user_assigned_identity.workload_identity.client_id
}

# Fetch current executing client config (your user/service principal)
data "azurerm_client_config" "current" {}

# Grant the executing user permissions to read/write secrets in this Key Vault
resource "azurerm_role_assignment" "terraform_user_kv_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}