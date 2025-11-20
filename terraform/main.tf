##############################
# Resource Group
##############################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

##############################
# Azure Container Registry
##############################
resource "azurerm_container_registry" "acr" {
  name                = "acraksdemounique123" # Updated to a globally unique name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

##############################
# Key Vault
##############################
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
}

##############################
# Key Vault Secret
##############################
resource "azurerm_key_vault_secret" "db" {
  name         = "db-password"
  value        = var.db_password                  # from GitHub Actions
  key_vault_id = azurerm_key_vault.kv.id
}

##############################
# AKS Cluster
##############################
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.aks_name}-dns"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_key_vault_secret.db]
}

##############################
# Key Vault Access Policy for AKS
##############################
resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

##############################
# Key Vault Access for GitHub Actions SP
##############################
resource "azurerm_key_vault_access_policy" "gha" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set"]
}
