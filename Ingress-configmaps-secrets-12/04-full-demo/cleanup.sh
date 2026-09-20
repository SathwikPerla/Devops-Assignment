#!/usr/bin/env bash
kubectl delete -f 04-full-demo/ingress.yaml --ignore-not-found
kubectl delete -f 04-full-demo/backend.yaml --ignore-not-found
kubectl delete -f 04-full-demo/frontend.yaml --ignore-not-found
kubectl delete -f 04-full-demo/secret.yaml --ignore-not-found
kubectl delete -f 04-full-demo/configmap.yaml --ignore-not-found
