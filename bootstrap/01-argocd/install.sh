#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=argocd
MANIFEST=https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "→ Создаю namespace $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "→ Применяю манифест ArgoCD (server-side, чтобы обойти лимит аннотации)"
kubectl apply -n "$NAMESPACE" --server-side --force-conflicts -f "$MANIFEST"

echo "→ Жду готовности argocd-server"
kubectl -n "$NAMESPACE" wait --for=condition=available \
  --timeout=300s deployment/argocd-server

echo "✅ ArgoCD установлен"
echo "   Пароль: kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"