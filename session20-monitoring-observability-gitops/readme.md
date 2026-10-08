# Session 20 — Monitoring, Observability & GitOps

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

# Task 1: Monitoring

### 1. Concepts (4-Line Summaries)

#### Metrics
1. Metrics are numerical, aggregatable data points measured over fixed intervals (counters, gauges, histograms).
2. They reflect point-in-time system behavior like request rate, saturation, and latency percentiles.
3. Because they are compact numeric timeseries, they require minimal storage and can be queried rapidly.
4. Tools like Prometheus and Datadog use metrics to evaluate alerting rules and render dashboards.

#### Logs
1. Logs are timestamped, discrete textual records emitted by applications and infrastructure when events occur.
2. They capture rich context (stack traces, user IDs, error codes) explaining *why* an event or failure happened.
3. While metrics signal that a system is unhealthy, logs provide the forensic detail required to debug issues.
4. Modern systems ship structured JSON logs to aggregators like Fluent Bit, Loki, Elasticsearch, or CloudWatch.

#### Alerts
1. Alerts are automated notifications triggered when metrics or log patterns breach predefined critical thresholds.
2. They notify on-call engineers via channels like PagerDuty, Slack, or email before service-level agreements degrade.
3. Good alerts focus on symptoms affecting end users (e.g., error rate > 1%) rather than transient internal noise.
4. Alerting rules define severity levels (Warning, Critical) and evaluation duration windows to prevent flapping.

#### CPU Utilization
1. CPU utilization measures the percentage or core count of compute capacity actively consumed by a workload.
2. High sustained CPU (>80-90%) causes thread starvation, throttling, queued requests, and severe latency spikes.
3. In Kubernetes, CPU is measured in millicores (`m`) where `1000m` equals one virtual core.
4. It is governed via `requests` (scheduling baseline) and `limits` (cgroup CFS quota enforcement).

#### Memory Utilization
1. Memory utilization tracks RAM bytes consumed by active processes, heaps, and cached buffers.
2. Unlike CPU, memory cannot be throttled; exceeding allocated memory limits triggers kernel Out-Of-Memory (OOM) kills.
3. In Kubernetes, pods exceeding their memory limit receive status `OOMKilled` and are immediately restarted.
4. Monitoring memory leaks prevents runaway consumption and unexpected cluster node instability.

#### Application Health
1. Application health evaluates whether a software service is alive, functioning properly, and ready to accept traffic.
2. It is typically verified via dedicated health endpoints (`/healthz`, `/livez`, `/readyz`) returning HTTP status codes.
3. Kubernetes relies on Liveness Probes to restart unhealthy containers and Readiness Probes to route ingress traffic.
4. Continuous health checks prevent deadlocked processes from degrading overall system availability.

---

### 2. Hands-on Monitoring Demo

#### Monitored Application Deployment (`monitoring-demo/deployment.yaml`)
Configured with CPU/Memory requests & limits, and Liveness & Readiness health probes:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: monitored-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: monitored-app
  template:
    metadata:
      labels:
        app: monitored-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

#### Node CPU & Memory Utilization
```bash
kubectl top nodes
```
**Output:**
```text
NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
minikube   162m         1%       1883Mi          24%
```
![Node Utilization Metrics](screenshots/01_metrics_top_nodes.png)

---

#### Pod CPU & Memory Utilization
```bash
kubectl top pods -l app=monitored-app
```
**Output:**
```text
NAME                             CPU(cores)   MEMORY(bytes)   
monitored-app-6c649dd9c4-67q82   2m           8Mi             
monitored-app-6c649dd9c4-kr9nl   2m           9Mi
```
![Pod Utilization Metrics](screenshots/02_metrics_top_pods.png)

---

#### Application Health & Readiness Verification
```bash
kubectl get pods -l app=monitored-app -o wide
```
**Output:**
```text
NAME                             READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
monitored-app-6c649dd9c4-67q82   1/1     Running   0          2m    10.244.0.42   minikube   <none>           <none>
monitored-app-6c649dd9c4-kr9nl   1/1     Running   0          2m    10.244.0.41   minikube   <none>           <none>
```
![Application Health Probes](screenshots/03_app_health_probes.png)

---

#### Container Logs Capturing Probe Requests
```bash
kubectl logs -l app=monitored-app --tail=6
```
**Output:**
```text
10.244.0.1 - - [08/Oct/2026:13:45:39 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
10.244.0.1 - - [08/Oct/2026:13:45:44 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
10.244.0.1 - - [08/Oct/2026:13:45:49 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
10.244.0.1 - - [08/Oct/2026:13:45:54 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
10.244.0.1 - - [08/Oct/2026:13:45:59 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
10.244.0.1 - - [08/Oct/2026:13:46:04 +0000] "GET / HTTP/1.1" 200 896 "-" "kube-probe/1.37" "-"
```
![Application Logs](screenshots/04_application_logs.png)

---

# Task 2: Observability

### 1. The Three Major Pillars (4-Line Summaries)

#### Pillar 1: Metrics
1. Metrics provide aggregated numeric representations of system health measured at consistent intervals.
2. They answer *"Is the system working?"* and *"What is current resource load and error frequency?"*.
3. Formatted as counters (monotonically increasing), gauges (variable values), or histograms (latency distributions).
4. Ideal for real-time alerting, trend analysis, and capacity forecasting due to efficient storage.

#### Pillar 2: Logs
1. Logs capture timestamped contextual event descriptions generated as code executes.
2. They answer *"Why did the failure or unexpected behavior happen?"* by providing stack traces and input context.
3. Usually structured in JSON format with log levels (`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`).
4. Essential for forensic analysis, audit tracking, and debugging intermittent logic defects.

#### Pillar 3: Traces
1. Distributed traces track the lifecycle and path of an individual user request through complex microservices.
2. They answer *"Where did the delay occur?"* by breaking down request execution into correlated parent-child spans.
3. Each span records latency, service name, metadata, and errors encountered along the request network hop.
4. Invaluable for pinpointing hidden microservice bottlenecks and distributed dependency failures.

---

### 2. Core Concepts (4-Line Summaries)

#### What Each Pillar Means
1. Metrics tell you **that** a problem is happening through numerical thresholds and spike indicators.
2. Traces pinpoint **where** in the distributed architecture the bottleneck or broken component is located.
3. Logs reveal **why** the component broke by exposing the exact line of code, exception, and parameters.
4. Combined together, they transform blind troubleshooting into deterministic, fast root-cause isolation.

#### Why Observability is Required
1. Modern cloud-native microservices and Kubernetes architectures have highly dynamic, distributed failure modes.
2. Traditional passive monitoring only checks for known failure modes ("known-unknowns") through static threshold alerts.
3. Observability enables engineers to interrogate systems about unpredictable states ("unknown-unknowns") via telemetry data.
4. It dramatically slashes Mean Time to Detect (MTTD) and Mean Time to Resolution (MTTR) during production outages.

#### Common Observability Tools
1. **Prometheus & VictoriaMetrics:** Industry-standard timeseries engines for pulling, storing, and alerting on metrics.
2. **Grafana:** Universal dashboarding and visualization platform uniting metrics, logs, and distributed traces in single panes.
3. **Jaeger & Zipkin:** Distributed tracing backends visualizing transaction flow graphs and request span waterfalls.
4. **Grafana Loki & OpenTelemetry:** Loki provides cost-effective log indexing; OpenTelemetry standardizes vendor-neutral telemetry collection.

#### Kubernetes Observability
1. Kubernetes clusters require observability across three distinct layers: Nodes, Cluster Control Plane, and Container Pods.
2. Metrics-server and `kube-state-metrics` export cluster object states and live CPU/memory resource usage.
3. DaemonSets (e.g., Promtail, Fluent Bit) tail container log files from `/var/log/pods` on each cluster node.
4. Ingress controllers and service meshes (Istio, Linkerd) inject trace headers to correlate inter-pod traffic.

---

# Task 3: GitOps

### 1. GitOps Fundamentals (4-Line Summaries)

#### What is GitOps?
1. GitOps is an operational framework that uses Git repositories as the single source of truth for cloud infrastructure and applications.
2. Developers manage environments through standard Git workflows (Pull Requests, code reviews, branch merges).
3. Software agents running inside clusters automatically synchronize live states to match Git declarations.
4. It eliminates direct cluster access (`kubectl apply` via local machines), boosting security and auditability.

#### Git as the Source of Truth
1. The entire desired state of the infrastructure and Kubernetes workloads is declared and version-controlled in Git.
2. Any configuration change, rollback, or environment scaling event begins as an auditable Git commit.
3. Git history provides an immutable audit log detailing who changed what, when, and for what business reason.
4. Disaster recovery is streamlined: an entire cluster can be rebuilt purely by pointing a new cluster at the Git repo.

#### Declarative Configuration
1. Systems are described by their desired end state (e.g., `replicas: 3`, `version: 1.25`) rather than imperative procedures.
2. Kubernetes YAML manifests, Helm charts, and Kustomize overlays serve as declarative configuration artifacts.
3. Declarative models are idempotent, meaning applying them repeatedly produces the exact same expected outcome.
4. They enable automated diffing between what is declared in Git and what is actively running in production.

#### Continuous Reconciliation
1. A GitOps controller (like Argo CD or Flux) runs a continuous feedback loop comparing desired state with live cluster state.
2. If drift occurs (e.g., manual edits or crashed pods), the controller immediately detects the divergence.
3. Depending on policy, the agent self-heals by overriding out-of-band modifications back to Git's declared state.
4. This active reconciliation guarantees continuous cluster integrity and prevents configuration drift over time.

#### GitOps Workflow
1. A developer creates a branch, commits declarative manifest changes, and opens a Pull Request (PR).
2. Automated CI pipelines run linters, security scans, unit tests, and plan previews on the PR branch.
3. Team leads review and merge the PR into the target release branch (`main` or `production`).
4. The GitOps operator running inside the cluster detects the merge commit, reconciles, and deploys the updates automatically.

#### Kubernetes + GitOps
1. Kubernetes' declarative API and control loop architecture make it the native platform for GitOps principles.
2. Tools like **Argo CD** and **Flux CD** run directly inside the cluster as Custom Resource Definitions (CRDs).
3. Security is hardened: CI systems do not require admin cluster credentials; only the internal GitOps agent has deploy rights.
4. Rollbacks become instantaneous: running `git revert` triggers the operator to immediately revert the running workloads.

---

### 2. Hands-on GitOps Demo

#### GitOps Application Manifests (`gitops-demo/app-manifests/`)
Declarative target workload managed under version control:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitops-workload
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gitops-workload
  template:
    metadata:
      labels:
        app: gitops-workload
    spec:
      containers:
      - name: web
        image: nginx:1.25-alpine
```

#### Argo CD Declarative Application Resource (`gitops-demo/argocd-application.yaml`)
Configures automated continuous reconciliation, self-healing, and pruning:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-workload-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/SathwikPerla/Devops-Assignment.git
    targetRevision: main
    path: session20-monitoring-observability-gitops/gitops-demo/app-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Deployed GitOps Workload State
```bash
kubectl get pods,svc -l app=gitops-workload
```
**Output:**
```text
NAME                                   READY   STATUS    RESTARTS   AGE
pod/gitops-workload-67b76bb49b-f9gzd   1/1     Running   0          45s
pod/gitops-workload-67b76bb49b-rwq65   1/1     Running   0          45s
pod/gitops-workload-67b76bb49b-zbd55   1/1     Running   0          45s

NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/gitops-workload-svc   ClusterIP   10.102.207.97   <none>        80/TCP    45s
```
![GitOps Workload State](screenshots/05_gitops_workload.png)

---

#### Continuous Reconciliation & Sync Status
```bash
argocd app get gitops-workload-app
```
**Output:**
```text
Name:               argocd/gitops-workload-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://argocd.local/applications/gitops-workload-app
Repo:               https://github.com/SathwikPerla/Devops-Assignment.git
Target:             main
Path:               session20-monitoring-observability-gitops/gitops-demo/app-manifests
Sync Window:        Sync Allowed
Sync Status:        Synced to main (400cff8)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME                 STATUS  HEALTH   HOOK  MESSAGE
       Service     default    gitops-workload-svc  Synced  Healthy        service/gitops-workload-svc created
apps   Deployment  default    gitops-workload      Synced  Healthy        deployment.apps/gitops-workload created
```
![ArgoCD Continuous Reconciliation](screenshots/06_gitops_reconciliation.png)

---

## 3. Summary of Deliverables

| Deliverable | Location | Description |
| :--- | :--- | :--- |
| **Monitoring Demo** | [`monitoring-demo/`](monitoring-demo/) | Deployment with resource limits, liveness & readiness probes, and Prometheus alert rules |
| **GitOps Demo** | [`gitops-demo/`](gitops-demo/) | Declarative app manifests and ArgoCD Application custom resource for continuous sync |
| **Observability Docs** | [`readme.md`](readme.md) | 4-line summaries covering Metrics, Logs, Traces, tools, and Kubernetes observability |
| **Terminal Screenshots** | [`screenshots/`](screenshots/) | High-resolution terminal captures verifying live node/pod metrics, health probes, and GitOps sync |
