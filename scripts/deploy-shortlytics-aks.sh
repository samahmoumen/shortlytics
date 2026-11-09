#!/usr/bin/env bash

set -euo pipefail


az aks get-credentials -g shortlytics-dev-rg -n shortlytics-dev-aks --overwrite-existing


kubectl create namespace argocd          --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace shortlytics-dev --dry-run=client -o yaml | kubectl apply -f -


kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s


bash setup-argocd-secrets.sh


helm repo add external-secrets https://charts.external-secrets.io
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true --wait


helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true --wait


helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --wait


kubectl apply -n argocd -f gitops-manifests/apps/dev/shortlytics-app.yaml


kubectl get pods -n shortlytics-dev
kubectl get svc ingress-nginx-controller -n ingress-nginx
