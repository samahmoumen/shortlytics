#!/bin/bash
set -e

ENV_NAME=${1:-dev}

echo "=========================================="
echo "1. Deploying Bootstrap Infrastructure..."
echo "=========================================="
cd terraform/bootstrap
terraform init -input=false
terraform apply -auto-approve
cd ../..

echo "=========================================="
echo "2. Deploying Environment: $ENV_NAME..."
echo "=========================================="
cd terraform/environments/$ENV_NAME
terraform init -input=false
terraform apply -auto-approve

echo "=========================================="
echo "3. Extracting Terraform Outputs..."
echo "=========================================="
ACR_SERVER=$(terraform output -raw acr_login_server)
KV_NAME=$(terraform output -raw key_vault_name)
CLIENT_ID=$(terraform output -raw workload_identity_client_id)

echo "-> ACR Login Server:          $ACR_SERVER"
echo "-> Key Vault Name:            $KV_NAME"
echo "-> Workload Identity Client ID: $CLIENT_ID"
cd ../../..

echo "=========================================="
echo "4. Patching GitOps Manifests..."
echo "=========================================="
# Fixed path to match your gitops-manifests/shortlytics/ directory structure
GITOPS_FILE="gitops-manifests/shortlytics/values-${ENV_NAME}.yaml"

if [ -f "$GITOPS_FILE" ]; then
  yq eval ".global.imageRegistry = \"$ACR_SERVER\"" -i "$GITOPS_FILE"
  yq eval ".global.azure.keyVaultName = \"$KV_NAME\"" -i "$GITOPS_FILE"
  yq eval ".global.azure.workloadIdentityClientId = \"$CLIENT_ID\"" -i "$GITOPS_FILE"
  echo "Successfully updated $GITOPS_FILE"
else
  echo "Error: $GITOPS_FILE not found!"
  exit 1
fi

echo "=========================================="
echo "Done! Review changes with 'git diff'."
echo "=========================================="
