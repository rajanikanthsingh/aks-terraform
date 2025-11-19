variable "location" {
  type    = string
  default = "East US"
}

variable "rg_name" {
  type    = string
  default = "rg-aks-demo"
}

variable "acr_name" {
  type    = string
  default = "acraksdemo"
}

variable "key_vault_name" {
  type    = string
  default = "kvaksdemo"
}

variable "aks_name" {
  type    = string
  default = "aks-demo"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_size" {
  type    = string
  default = "Standard_B2s"
}

# This value comes from GitHub Actions
variable "db_password" {
  type      = string
  sensitive = true
}

# GitHub Actions Service Principal ID
variable "github_actions_client_id" {
  type = string
}
