#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/create_backend.sh <subscription-id> <resource-group> <storage-account-name> <container-name>
# Example: ./scripts/create_backend.sh $(az account show --query id -o tsv) rg-terraform-state staterajaks tfstate

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <subscription-id> <resource-group> <storage-account-name> <container-name>"
  exit 2
fi

SUBSCRIPTION_ID=$1
RG_NAME=$2
STORAGE_ACCOUNT_NAME=$3
CONTAINER_NAME=$4

echo "Using subscription: $SUBSCRIPTION_ID"

az account set --subscription "$SUBSCRIPTION_ID"

echo "Creating resource group: $RG_NAME"
az group create -n "$RG_NAME" -l eastus --subscription "$SUBSCRIPTION_ID"

echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RG_NAME" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob \
  --subscription "$SUBSCRIPTION_ID"

echo "Getting storage account key"
STORAGE_KEY=$(az storage account keys list --resource-group "$RG_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --query "[0].value" -o tsv)

echo "Creating blob container: $CONTAINER_NAME"
az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY"

echo "Backend storage ready. Keep these values to configure 'terraform init -backend-config'."
echo "resource_group_name=$RG_NAME"
echo "storage_account_name=$STORAGE_ACCOUNT_NAME"
echo "container_name=$CONTAINER_NAME"
echo "key=aks-terraform.tfstate"

echo "If you'd like, export STORAGE_KEY to use in automation: export ARM_ACCESS_KEY=\"$STORAGE_KEY\""
