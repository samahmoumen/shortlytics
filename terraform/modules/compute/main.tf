# --- modules/compute/variables.tf ---
variable "resource_group" { type = string }
variable "location" { type = string }
variable "project_prefix" { type = string }
variable "subnet_id" { type = string }

# --- modules/compute/main.tf ---
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "${var.project_prefix}-aks"
  location                  = var.location
  resource_group_name       = var.resource_group
  dns_prefix                = var.project_prefix
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

 
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }
}

# --- modules/compute/outputs.tf ---
output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Kubelet Managed Identity Object ID used for AcrPull"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

