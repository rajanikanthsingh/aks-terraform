#!/usr/bin/env bash
set -euo pipefail

# cleanup.sh - Safe cleanup for resources created by this repo
# Actions performed (interactive):
#  - show current Azure subscription
#  - show resource group status
#  - show Key Vault (active or soft-deleted) and purge if requested
#  - delete ACR registry if exists
#  - delete resource group (if exists)
#  - remove resource locks if necessary

RG_NAME="rg-aks-demo"
KV_NAME="kvaksdemo"
ACR_NAME="acraksdemounique123"
LOCATION="eastus"

function check_az() {
  if ! command -v az &> /dev/null; then
    echo "az CLI not found. Install and login first: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
  fi
}

function show_subscription() {
  echo "Current Azure subscription:"
  az account show --query '{id:id, name:name}' -o json
}

function show_rg() {
  echo "\nChecking resource group '$RG_NAME'..."
  if az group show --name "$RG_NAME" &> /dev/null; then
    echo "Resource group '$RG_NAME' exists." 
    az group show --name "$RG_NAME" -o json
  else
    echo "Resource group '$RG_NAME' not found."
  fi
}

function show_kv() {
  echo "\nChecking Key Vault '$KV_NAME'..."
  if az keyvault show --name "$KV_NAME" &> /dev/null; then
    echo "Key Vault is active:" 
    az keyvault show --name "$KV_NAME" -o json
  else
    echo "Key Vault not active. Checking soft-deleted list..."
    az keyvault list-deleted --query "[?name=='$KV_NAME']" -o json
  fi
}

function purge_kv() {
  echo "\nPURGE Key Vault '$KV_NAME' (permanent!)"
  read -p "Are you sure you want to permanently purge the Key Vault '$KV_NAME'? This is irreversible. (type 'yes' to confirm): " ans
  if [[ "$ans" == "yes" ]]; then
    echo "Purging..."
    az keyvault purge --name "$KV_NAME" --location "$LOCATION"
    echo "Purge command issued. Check 'az keyvault list-deleted' to confirm it no longer appears."
  else
    echo "Skipping purge."
  fi
}

function delete_acr() {
  echo "\nChecking ACR '$ACR_NAME'..."
  if az acr show --name "$ACR_NAME" &> /dev/null; then
    az acr show --name "$ACR_NAME" -o json
    read -p "Delete registry '$ACR_NAME'? (type 'yes' to confirm): " ans
    if [[ "$ans" == "yes" ]]; then
      az acr delete --name "$ACR_NAME" --resource-group "$RG_NAME" --yes
      echo "ACR delete command issued."
    else
      echo "Skipping ACR deletion."
    fi
  else
    echo "ACR '$ACR_NAME' not found (or already deleted)."
  fi
}

function remove_locks() {
  echo "\nChecking for locks on resource group '$RG_NAME'..."
  locks=$(az lock list --resource-group "$RG_NAME" -o json 2>/dev/null || echo '[]')
  if [[ "$locks" == "[]" ]]; then
    echo "No locks found or resource group not present."
    return
  fi
  echo "Locks found:" 
  echo "$locks" | jq -r '.[] | "- id: \(.id)   name: \(.name)   level: \(.level)"'

  read -p "Delete all locks on the resource group? (type 'yes' to confirm): " ans
  if [[ "$ans" == "yes" ]]; then
    for id in $(echo "$locks" | jq -r '.[].id'); do
      echo "Deleting lock $id"
      az lock delete --ids "$id"
    done
    echo "All locks removed."
  else
    echo "Skipping lock removal."
  fi
}

function delete_rg() {
  echo "\nDelete Resource Group '$RG_NAME' and all contained resources (this is irreversible)."
  read -p "Type 'delete-rg' to confirm permanent deletion of the resource group: " ans
  if [[ "$ans" == "delete-rg" ]]; then
    echo "Deleting resource group..."
    az group delete --name "$RG_NAME" --yes --no-wait
    echo "Deletion initiated. Use 'az group show --name $RG_NAME' to check status." 
  else
    echo "Resource group deletion cancelled."
  fi
}

# Script entry
check_az
show_subscription
show_rg
show_kv

read -p "Do you want to purge the soft-deleted Key Vault (if present)? (yes/no): " purge_choice
if [[ "$purge_choice" == "yes" ]]; then
  purge_kv
fi

read -p "Do you want to delete the ACR registry (if present)? (yes/no): " acr_choice
if [[ "$acr_choice" == "yes" ]]; then
  delete_acr
fi

read -p "Do you want to remove locks on the resource group (if present)? (yes/no): " lock_choice
if [[ "$lock_choice" == "yes" ]]; then
  # jq required for lock listing; fall back if jq missing
  if ! command -v jq &>/dev/null; then
    echo "jq is not installed; install jq for nicer lock output or proceed with Azure Portal."
  fi
  remove_locks
fi

read -p "Do you want to delete the resource group '$RG_NAME'? (yes/no): " rg_choice
if [[ "$rg_choice" == "yes" ]]; then
  delete_rg
fi

echo "Cleanup script finished. Double-check resources in the Portal or via 'az' before proceeding." 
