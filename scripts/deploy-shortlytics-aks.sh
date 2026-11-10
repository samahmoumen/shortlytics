#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_GROUP="${RESOURCE_GROUP:-shortlytics-dev-rg}"
AKS_CLUSTER="${AKS_CLUSTER:-shortlytics-dev-aks}"

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace shortlytics-dev --dry-run=client -o yaml | kubectl apply -f -

kubectl apply --namespace argocd --server-side --force-conflicts \
  --filename https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server \
  --namespace argocd --timeout=300s

helm repo add external-secrets https://charts.external-secrets.io
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace --set installCRDs=true --wait

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace --set crds.enabled=true --wait

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.annotations."service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --wait

# The repository is public; Argo CD can read it without a GitHub PAT.
kubectl apply --namespace argocd --filename "$ROOT_DIR/gitops-manifests/apps/dev/shortlytics-app.yaml"

kubectl get pods --namespace argocd
kubectl get pods --namespace shortlytics-dev
kubectl get service ingress-nginx-controller --namespace ingress-nginx
