**AKS Terraform (AKS + ACR + Key Vault)**

- **Overview:** This repository provisions an Azure Resource Group, Azure Container Registry (ACR), Azure Key Vault, and an AKS cluster using Terraform. It also contains a GitHub Actions workflow that runs Terraform and deploys a containerized app to AKS.

**Repository Layout**
- `terraform/` : Terraform configuration (`main.tf`, `variable.tf`, etc.)
- `.github/workflows/deploy.yaml` : GitHub Actions workflow for Terraform + CI/CD
- `k8s/` : Kubernetes manifests (deployment.yaml)
- `Dockerfile`, `app.py` : sample app and container setup

**Prerequisites**
- Azure subscription and an Azure service principal with Contributor access to the target subscription or resource group.
- `az` CLI installed and logged in for local operations.
- `terraform` (tested with 1.6.0 in workflow).
- GitHub repository with Actions enabled and required secrets configured.

**Important Repository Secrets (GitHub Actions)**
- `AKSTERRAFORM_SUBSCRIPTION_ID`  : Azure subscription id
- `AKSTERRAFORM_TENANT_ID`        : Azure tenant id
- `AKSTERRAFORM_CLIENT_ID`        : Service principal client id
- `AKSTERRAFORM_CLIENT_SECRET`    : Service principal client secret
- `AKSTERRAFORM_DB_PASSWORD`      : Database password (passed to Terraform as `TF_VAR_db_password`)
- `AKSTERRAFORM_KEYVAULT_NAME`    : Key Vault name (used by fetch-secrets job)
- `AKSTERRAFORM_ACR_USERNAME`     : ACR username (optional)
- `AKSTERRAFORM_ACR_PASSWORD`     : ACR password (optional)

**Quick Local Usage**
1. Set environment variables (example):
```bash
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export TF_VAR_db_password='your-db-password'   # use single-quotes in zsh for `!`
```
2. Run Terraform from the `terraform` folder:
```bash
cd terraform
terraform init
terraform plan -var="node_size=standard_dc2s_v3"
terraform apply -auto-approve -var="node_size=standard_dc2s_v3"
```

**GitHub Actions**
- Workflow: `.github/workflows/deploy.yaml` runs `terraform init/plan/apply`, captures outputs, fetches Key Vault secrets, builds the Docker image, and deploys to AKS.
- The workflow passes the DB password with `TF_VAR_db_password: ${{ secrets.AKSTERRAFORM_DB_PASSWORD }}` so set that secret in the repo settings.
- To override node size for CI run, add `TF_VAR_node_size: <sku>` to the `terraform` job `env:` block.

**Key Notes & Troubleshooting**
- Key Vault access race: Terraform checks for an existing secret before creating it. The repo adds `depends_on = [azurerm_key_vault_access_policy.gha]` so the access policy is applied before `azurerm_key_vault_secret.db` is created. If you still see 403 errors, wait a few seconds and retry or import the existing access policy into state.

- Importing existing Key Vault access policy:
```bash
terraform import azurerm_key_vault_access_policy.gha "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kvname>/objectId/<object_id>"
```
- If Terraform reports a pre-existing resource, prefer importing it rather than deleting it from Azure (safer).

- Key Vault soft-delete: Deleted vaults may be soft-deleted and show `scheduledPurgeDate`. To permanently remove a soft-deleted vault:
```bash
az keyvault purge --name <kvname> --location <location>
```
Be cautious: purge is irreversible and may be blocked by purge protection.

- ACR registry: If the resource group was deleted but the portal shows a pinned tile, it is a stale dashboard reference. To find/inspect registries:
```bash
az acr show --name <acrName> -o json
az acr repository list --name <acrName> --output table
```
To delete a registry:
```bash
az acr delete --name <acrName> --resource-group <rg> --yes
```

- AKS vCPU quota errors: Free/trial subscriptions have low vCPU quotas. If you see `ErrCode_InsufficientVCPUQuota`:
  - Lower `node_size` (e.g., `standard_dc2s_v3`) or `node_count`.
  - Request a quota increase in the Azure Portal if you need larger SKUs.
  - Example variable override: `TF_VAR_node_size=standard_dc2s_v3`.

**Cleaning Up (delete everything)**
- Delete resource group (removes all resources inside it):
```bash
az group delete --name rg-aks-demo --yes
```
- If Key Vault is soft-deleted and you want it gone now:
```bash
az keyvault purge --name kvaksdemo --location eastus
```
- Remove locks if deletion is blocked:
```bash
az lock list --resource-group rg-aks-demo -o table
az lock delete --ids <lock-id>
```

**If Terraform State is out of sync**
- Remove orphaned resources from state (careful):
```bash
terraform state rm <resource_address>
```
- Or import existing Azure resource into state (see import examples above).

**Next Steps / Suggestions**
- Start with smaller AKS node sizes to fit free-tier quotas.
- Prefer importing existing Azure resources into Terraform rather than manually deleting them when possible.
- Keep secrets in GitHub Actions secrets and avoid echoing them in logs.

If you want, I can add more details (examples for importing ACR, scripts for purging, or add a `make` target).