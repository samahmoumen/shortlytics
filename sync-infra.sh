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

# Derive ACR_NAME (removes the .azurecr.io suffix) and RG_NAME
ACR_NAME=$(echo "$ACR_SERVER" | cut -d'.' -f1)
RG_NAME="shortlytics-${ENV_NAME}-rg"

echo "-> ACR Login Server:          $ACR_SERVER"
echo "-> ACR Name:                  $ACR_NAME"
echo "-> Key Vault Name:            $KV_NAME"
echo "-> Workload Identity Client ID: $CLIENT_ID"
cd ../../..

echo "=========================================="
echo "4. Patching GitOps Manifests & Scripts..."
echo "=========================================="

# A. Patch the Helm values file
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

# B. Patch the ArgoCD Application YAML
APP_FILE="gitops-manifests/apps/${ENV_NAME}/shortlytics-app.yaml"
if [ -f "$APP_FILE" ]; then
  # Replaces any existing '<anything>.azurecr.io' string with the new ACR_SERVER domain
  sed -i '' -E "s|[a-zA-Z0-9]+\.azurecr\.io|$ACR_SERVER|g" "$APP_FILE"
  echo "Successfully updated $APP_FILE"
else
  echo "Warning: $APP_FILE not found! Skipping..."
fi

# C. Patch the Secrets Setup Script
SECRETS_SCRIPT="setup-argocd-secrets.sh"
if [ -f "$SECRETS_SCRIPT" ]; then
  # Replaces the hardcoded RESOURCE_GROUP and ACR_NAME values
  sed -i '' -E "s/^RESOURCE_GROUP=\".*\"/RESOURCE_GROUP=\"$RG_NAME\"/" "$SECRETS_SCRIPT"
  sed -i '' -E "s/^ACR_NAME=\".*\"/ACR_NAME=\"$ACR_NAME\"/" "$SECRETS_SCRIPT"
  echo "Successfully updated $SECRETS_SCRIPT"
else
  echo "Warning: $SECRETS_SCRIPT not found! Skipping..."
fi

echo "=========================================="
echo "Done! Review changes with 'git diff'."
echo "=========================================="