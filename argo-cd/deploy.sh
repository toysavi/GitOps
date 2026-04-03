#!/bin/bash
set -e
source .env

# === Deploy ArgoCD ===
echo "Deploying ArgoCD..."
kubectl create namespace argocd || true
kubectl apply -n argocd -f ./argo-cd/src/argocd/

# Ingress for ArgoCD
kubectl apply -n argocd -f ./argo-cd/src/argocd-ingress.yaml

# === Deploy Monitoring Stack ===
echo "Deploying Prometheus, Grafana, Alertmanager..."
kubectl create namespace monitoring || true
kubectl apply -n monitoring -f ./argo-cd/src/monitoring/

# Ingress for Monitoring
kubectl apply -n monitoring -f ./argo-cd/src/monitoring-ingress.yaml

echo "Deployment complete."
echo "Access services at:"
echo "  ArgoCD: https://${ARGOCD_HOST}"
echo "  Prometheus: https://${PROMETHEUS_HOST}"
echo "  Grafana: https://${GRAFANA_HOST}"
echo "  Alertmanager: https://${ALERTMANAGER_HOST}"
