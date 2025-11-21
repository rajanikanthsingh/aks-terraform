terraform {
  backend "azurerm" {}
}

/*
Notes:
- This file declares the azurerm backend type but does NOT hard-code backend settings
  (resource group, storage account, container, key). Configure those values at
  `terraform init` time with `-backend-config` flags or create a separate
  `backend.tfvars` that is NOT committed.

Example init (after creating storage account/container):
  terraform init \
    -backend-config="resource_group_name=rg-terraform-state" \
    -backend-config="storage_account_name=staksterraformstate" \
    -backend-config="container_name=tfstate" \
    -backend-config="key=aks-terraform.tfstate"

See the repository README for usage instructions.
*/
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstateaccountdemo"
#     container_name       = "tfstate"
#     key                  = "aks-demo.terraform.tfstate"
#   }
# }
