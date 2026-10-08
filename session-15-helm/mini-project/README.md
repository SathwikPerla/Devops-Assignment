# Mini Project: Notes Application Helm Chart

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. Project Overview

The objective of this mini-project is to package, parameterize, and deploy a multi-environment web application using Helm. Instead of managing static, error-prone Kubernetes YAML manifests per environment, we maintain a single reusable chart (`notes-chart`) with distinct values files for `development` and `production`.

---

## 2. Chart Layout

```text
mini-project/notes-chart/
├── Chart.yaml              # Chart metadata (name, version, appVersion)
├── values.yaml             # Development defaults (1 replica, nginx 1.24, dev environment)
├── values-prod.yaml        # Production overrides (3 replicas, nginx 1.25, prod environment)
└── templates/
    ├── configmap.yaml      # Parameterized ConfigMap with app name and environment
    ├── deployment.yaml     # Parameterized Deployment injecting ConfigMap and replica counts
    └── service.yaml        # Parameterized Service routing traffic to application pods
```

---

## 3. Manifest Files

### Chart.yaml
```yaml
apiVersion: v2
name: notes-chart
description: A simple Notes application Helm chart
type: application
version: 0.1.0
appVersion: "1.0"
```

### values.yaml (Development)
```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.24"

service:
  type: ClusterIP
  port: 80

app:
  name: notes-app
  environment: development
```

### values-prod.yaml (Production)
```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"

service:
  type: ClusterIP
  port: 80

app:
  name: notes-app
  environment: production
```

### templates/configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  APP_NAME: {{ .Values.app.name | quote }}
  ENVIRONMENT: {{ .Values.app.environment | quote }}
```

### templates/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deploy
  labels:
    app: {{ .Release.Name }}
    environment: {{ .Values.app.environment }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: notes
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ .Release.Name }}-config
```

### templates/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
```

---

## 4. Execution & Verification Flow

| Step | Action | Command | Verification |
| :--- | :--- | :--- | :--- |
| **1. Lint** | Syntax & schema validation | `helm lint notes-chart` | 0 chart(s) failed |
| **2. Template** | Dry-run template rendering | `helm template notes-dev notes-chart` | Evaluates Go templates |
| **3. Install Dev** | Deploy development release | `helm install notes-dev notes-chart` | Deploys 1 replica (v1.24) |
| **4. Upgrade Prod**| Apply production values | `helm upgrade notes-dev notes-chart -f values-prod.yaml` | Scales to 3 replicas (v1.25) |
| **5. Fault Injection**| Deploy broken image | `helm upgrade notes-dev notes-chart --set image.tag=broken-tag-does-not-exist` | Produces `ErrImagePull` |
| **6. Rollback** | Restore healthy revision | `helm rollback notes-dev 2` | Restores 3 healthy pods |
| **7. Cleanup** | Teardown release | `helm uninstall notes-dev` | Releases cluster resources |
