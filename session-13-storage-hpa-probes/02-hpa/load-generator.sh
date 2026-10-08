#!/bin/bash
# Load generator for HPA testing
echo "Launching load generator..."
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
echo "Load generator running. Monitor with: kubectl get hpa -w"
