# Mini Project: Resilient Production-Ready Kubernetes Web App

## Architecture
- **Namespace**: `production-webapp` (strict workload isolation)
- **Persistent Storage**: 500Mi PVC dynamically provisioned using `standard` StorageClass, mounted at `/data`
- **Application Pods**: Nginx 1.27 with explicit CPU (100m req / 200m limit) and Memory (64Mi req / 128Mi limit) resources
- **Probes**:
  - **Startup Probe**: `HTTP GET /:80` (allows slow starts up to 60s without premature killing)
  - **Readiness Probe**: `HTTP GET /:80` (removes unready pods from Service endpoints)
  - **Liveness Probe**: `HTTP GET /:80` (restarts deadlocked or failed containers)
- **Networking**: ClusterIP Service `web-service` routing port 80
- **Autoscaling**: HPA `web-app-hpa` maintaining 50% target CPU utilization, scaling from 2 to 5 replicas

## Deployment Steps
```bash
kubectl apply -f namespace.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

## Verification Scenarios
1. **Storage Persistence**: Write data to `/data/student.txt`, delete pod, verify that recreated pod retains identical file.
2. **Probes & Readiness**: Observe `1/1 READY` condition and endpoints association.
3. **Autoscaling Under Load**: Launch load generator and observe replicas scaling from 2 to 5.
