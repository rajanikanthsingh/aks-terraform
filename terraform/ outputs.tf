output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}
