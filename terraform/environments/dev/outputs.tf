output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "ACR Registry URL to inject into Helm global.imageRegistry"
  value       = module.security.acr_login_server
}

output "key_vault_name" {
  description = "Key Vault Name to inject into Helm global.azure.keyVaultName"
  value       = module.security.key_vault_name
}

output "workload_identity_client_id" {
  description = "Managed Identity Client ID for global.azure.workloadIdentityClientId"
  value       = module.security.workload_identity_client_id
}

output "private_dns_zone_name" {
  description = "Private DNS zone for internal cluster ingress"
  value       = module.network.private_dns_zone_name
}