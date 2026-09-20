#!/usr/bin/env bash
set -e
echo "Enabling Ingress addon..."
minikube addons enable ingress

echo "Applying manifests..."
kubectl apply -f 04-full-demo/configmap.yaml
kubectl apply -f 04-full-demo/secret.yaml
kubectl apply -f 04-full-demo/frontend.yaml
kubectl apply -f 04-full-demo/backend.yaml
kubectl apply -f 04-full-demo/ingress.yaml

echo "Waiting for pods to be ready..."
kubectl rollout status deployment/yatri-frontend --timeout=90s
kubectl rollout status deployment/yatri-backend --timeout=90s

echo "Full demo ready!"
