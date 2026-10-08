# Session 14 — Kubernetes Troubleshooting

## Task 1: Essential Troubleshooting Commands

Important troubleshooting commands covered in hands-on practice:
```bash
# Check status, IP, and node assignment
kubectl get pods -o wide

# Inspect container state, lifecycle, and event logs
kubectl describe pod <pod-name>

# View container logs (current or previous crash)
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Interactive debugging inside a running container
kubectl exec -it <pod-name> -- sh

# View chronological cluster warning and error events
kubectl events

# Inspect API resource specifications and schemas
kubectl explain pod.spec.containers

# Monitor live CPU and memory utilization
kubectl top nodes
kubectl top pods
```

---

## Task 2: Troubleshooting Common Issues

Commands and investigation flow for common Kubernetes issues:

* **CrashLoopBackOff**:
  * Investigate: `kubectl describe pod <pod>` & `kubectl logs <pod> --previous`
  * Cause & Fix: Application crash or missing env/entrypoint; fix application command or configuration.
* **ImagePullBackOff / ErrImagePull**:
  * Investigate: `kubectl describe pod <pod>` (inspect `Events`)
  * Cause & Fix: Non-existent image tag or missing pull secret; fix image tag or add `imagePullSecrets`.
* **Pending**:
  * Investigate: `kubectl describe pod <pod>` (inspect `Events`)
  * Cause & Fix: Insufficient CPU/memory or unbound PVC; adjust resource requests or attach storage.
* **ContainerCreating**:
  * Investigate: `kubectl describe pod <pod>` (inspect `Events`)
  * Cause & Fix: Delayed PVC attachment or missing ConfigMap/Secret; resolve volume lock or create missing secret.
* **Service Connectivity**:
  * Investigate: `kubectl get endpoints <service>` & `kubectl describe svc <service>`
  * Cause & Fix: Selector does not match pod labels; align Service `spec.selector` with Pod labels.
* **DNS Issues**:
  * Investigate: `kubectl get pods -n kube-system -l k8s-app=kube-dns` & `nslookup <service>`
  * Cause & Fix: CoreDNS unready or domain mismatch; verify CoreDNS pods and cluster local domain.
* **Pod Networking**:
  * Investigate: `kubectl get pods -o wide` & pod-to-pod ping
  * Cause & Fix: CNI plugin failure or NetworkPolicy blocking traffic; verify CNI state and policy rules.
* **Configuration Issues**:
  * Investigate: `kubectl describe pod <pod>` (`CreateContainerConfigError`)
  * Cause & Fix: Missing ConfigMap/Secret key; create the referenced key or correct name in YAML.

---

## Task 3: Mini Project — Troubleshooting Challenge

### 1. Application & Service Deployment
```bash
kubectl apply -f mini-project/deployment.yaml
kubectl apply -f mini-project/service.yaml
kubectl get pods,svc,endpoints -l app=troubleshooting-app -o wide
```
![01-deploy-app-and-service](screenshots-mini/01-deploy-app-and-service.png)

### 2. Broken Pod Investigation (`ImagePullBackOff`)
* **Problem**: Pod stuck in `ErrImagePull` / `ImagePullBackOff`.
* **Investigation Command**:
```bash
kubectl apply -f mini-project/broken-pod.yaml
kubectl get pod project-broken-pod
kubectl describe pod project-broken-pod | tail -n 9
```
* **Root Cause**: Invalid image tag `nginx:this-tag-does-not-exist`.
![02-broken-pod-error](screenshots-mini/02-broken-pod-error.png)

### 3. Broken Pod Fixed
* **Fix**: Updated image tag to `nginx:alpine` in `fixed-pod.yaml`.
* **Verification Command**:
```bash
kubectl apply -f mini-project/fixed-pod.yaml
kubectl wait --for=condition=Ready pod/project-broken-pod --timeout=20s
kubectl get pod project-broken-pod
```
![03-broken-pod-fixed](screenshots-mini/03-broken-pod-fixed.png)

### 4. Service Selector Mismatch Investigation
* **Problem**: Service active but endpoints list is `<none>` (traffic fails).
* **Investigation Command**:
```bash
kubectl apply -f mini-project/broken-service.yaml
kubectl get endpoints troubleshooting-service
kubectl describe service troubleshooting-service | grep -E '(Selector|Endpoints):'
```
* **Root Cause**: Service selector `app: wrong-app` did not match Pod label `app: troubleshooting-app`.
![04-broken-service-no-endpoints](screenshots-mini/04-broken-service-no-endpoints.png)

### 5. Service Fixed & Verified
* **Fix**: Restored selector `app: troubleshooting-app` in `service.yaml`.
* **Verification Command**:
```bash
kubectl apply -f mini-project/service.yaml
kubectl get endpoints troubleshooting-service
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- curl -s http://troubleshooting-service:80 | head -n 6
```
![05-service-fixed-endpoints](screenshots-mini/05-service-fixed-endpoints.png)


# `kubectl get`

```bash
kubectl get
```

Think of `kubectl get` as:

> "Kubernetes, show me what is currently happening."

---

## 1. Create the Pod

Run:
```bash
kubectl apply -f pod.yaml
```

Expected output:
```text
pod/get-demo created
```

---

## 2. Check Pods

Run:
```bash
kubectl get pods
```

Expected output:
```text
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          10s
```

![Pod Creation and Status](screenshots/image-1.png)

---

## 3. Understand The Output

* **NAME**: Name of the Pod.
* **READY**: Number of ready containers.
* **STATUS**: Current Pod status.
* **RESTARTS**: Number of container restarts.
* **AGE**: How long the Pod has existed.

---

## 4. Get More Information

Run:
```bash
kubectl get pods -o wide
```

Output shows Pod IP, Node placement, and readiness gates:
```text
NAME       READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
get-demo   1/1     Running   0          25s   10.244.0.60   minikube   <none>           <none>
```

![Inspect with -o wide](screenshots/image-2.png)

---

## 5. Check Different Resources

**Pods:**
```bash
kubectl get pods
```

**Services:**
```bash
kubectl get services
```

**Deployments:**
```bash
kubectl get deployments
```

**Nodes:**
```bash
kubectl get nodes
```

**All resources:**
```bash
kubectl get all
```

![Multi-Resource Queries](screenshots/image-3.png)

---

## 6. Watch Changes

Run:
```bash
kubectl get pods -w
```

Delete the Pod:
```bash
kubectl delete pod get-demo
```

You can watch the Pod transition from `Running` to `Terminating` in real time.

![Watch Real-time Pod Deletion](screenshots/image-4.png)

---

## 7. Troubleshooting Habit

When something is not working, start with:
```bash
kubectl get pods
```

Then look at:
* `STATUS`
* `READY`
* `RESTARTS`

For example:
```text
NAME       READY   STATUS             RESTARTS
my-app     0/1     CrashLoopBackOff   5
```

This immediately signals container failure. Use `kubectl describe` and `kubectl logs` to discover root causes.

---

## Useful Commands

```bash
kubectl get pods
kubectl get pods -o wide
kubectl get all
kubectl get nodes
kubectl get services
kubectl get deployments
kubectl get pods -w
```

---

## Key Learning

```text
kubectl get
     │
     ▼
"What is happening?"
```

It provides the current observed state of Kubernetes resources.
