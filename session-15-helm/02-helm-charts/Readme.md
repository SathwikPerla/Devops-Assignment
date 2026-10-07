# Session 14 - Kubernetes Troubleshooting

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## Overview

Kubernetes troubleshooting requires a systematic, evidence-driven approach rather than guesswork. The foundational command for any investigation is `kubectl get`, which answers the primary question: **"What is currently happening in the cluster?"**

---

# Part 1: `kubectl get` — Inspecting Workload & Cluster State

## Step 1: Create the Pod & Step 2: Check Pod Status

Create the sample NGINX pod manifest:
```bash
kubectl apply -f 01-kubectl-get/pod.yaml
```
Expected Output:
```text
pod/get-demo created
```

Verify pod creation and status:
```bash
kubectl get pods
```
Output:
```text
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          10s
```

![Pod Created & Inspected](01-kubectl-get/screenshots/image-1.png)

---

## Step 3: Understanding the Output Columns

| Column | Meaning | Diagnostic Significance |
| :--- | :--- | :--- |
| **NAME** | Unique identifier of the resource. | Identifies which instance has issues. |
| **READY** | `ReadyContainers / TotalContainers` | Shows if all containers passed readiness checks. |
| **STATUS** | Current lifecycle phase. | Immediate indicator (`Running`, `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`). |
| **RESTARTS** | Number of container restarts. | High counts signal application crashes or OOM events. |
| **AGE** | Time elapsed since creation. | Helps correlate issues with recent rollouts or updates. |

---

## Step 4: Get Detailed Information (`-o wide`)

To retrieve network and node placement metadata without describing the full spec, run:
```bash
kubectl get pods -o wide
```
Output:
```text
NAME       READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
get-demo   1/1     Running   0          25s   10.244.0.60   minikube   <none>           <none>
```

![Detailed Pod Metadata with -o wide](01-kubectl-get/screenshots/image-2.png)

---

## Step 5: Check Different Resource Types

Query cluster resources to evaluate the overall system state:

* **Pods:**
  ```bash
  kubectl get pods
  ```
* **Services:**
  ```bash
  kubectl get services
  ```
* **Deployments:**
  ```bash
  kubectl get deployments
  ```
* **Nodes:**
  ```bash
  kubectl get nodes
  ```
* **All Resources:**
  ```bash
  kubectl get all
  ```

![Multi-Resource Queries](01-kubectl-get/screenshots/image-3.png)

---

## Step 6: Watch Changes in Real Time

Observe live lifecycle transitions:
```bash
kubectl get pods -w
```

When the pod is deleted via `kubectl delete pod get-demo`, watch updates stream live:
```text
NAME       READY   STATUS        RESTARTS   AGE
get-demo   1/1     Running       0          45s
get-demo   1/1     Terminating   0          48s
get-demo   0/1     Terminating   0          49s
get-demo   0/1     Terminating   0          50s
get-demo   0/1     Terminating   0          50s
```

![Watch Real-time Pod Deletion](01-kubectl-get/screenshots/image-4.png)

---

## Step 7: Troubleshooting Habit & Mindset

When an application fails or behaves unexpectedly:

1. **Start with:**
   ```bash
   kubectl get pods
   ```
2. **Inspect the triad:**
   * `STATUS` — Is it `Running`, `CrashLoopBackOff`, or `Pending`?
   * `READY` — Are all containers healthy (e.g. `0/1` vs `1/1`)?
   * `RESTARTS` — Is the crash count climbing?
3. **Escalate to Deep Diagnostics:**
   `kubectl get` identifies **WHAT** is happening. Use subsequent commands to understand **WHY**:
   * `kubectl describe pod <pod-name>` (Events, failure reasons, exit codes)
   * `kubectl logs <pod-name>` (Application stdout/stderr)

---

## Useful Commands Summary

```bash
kubectl get pods
kubectl get pods -o wide
kubectl get all
kubectl get nodes
kubectl get services
kubectl get deployments
kubectl get pods -w
```
