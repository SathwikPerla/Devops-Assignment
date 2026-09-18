# Session 9 - Kubernetes Architecture & Local Cluster Setup

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. Hands-On: Local Cluster Setup & Verification

To understand the core architecture components in action, a local single-node Kubernetes cluster is provisioned and inspected using `minikube` and `kubectl`.

### Step 1: Verify Installed Tools
```bash
minikube version
kubectl version --client
```

---

### Step 2: Start the Kubernetes Cluster
```bash
minikube start
```

---

### Step 3: Check Cluster Health & Status
```bash
minikube status
```

---

### Step 4: Verify Node Status
```bash
kubectl get nodes
```

---

### Step 5: Stop the Cluster
```bash
minikube stop
```

### Evidence: Terminal Execution

![alt text](<Screenshot 2026-09-18 at 7.10.21 PM.png>)

---

## 2. Kubernetes Architecture Overview

Kubernetes follows a **master-worker (client-server)** architecture distributed across two primary layers:

1. **Control Plane:** The cluster's "brain" responsible for global decision-making, scheduling workloads, detecting events, and managing cluster state.
2. **Worker Node:** The cluster's "worker" responsible for hosting containerized workloads (Pods) and maintaining runtime networking.

```text
                  +-------------------------------------------------+
                  |                 CONTROL PLANE                   |
                  |                                                 |
                  |               +-----------------+               |
                  |               | kube-apiserver  |<---+          |
                  |               +--------+--------+    |          |
                  |                        |             |          |
                  |         +--------------+-------------+          |
                  |         |              |             |          |
                  |         v              v             v          |
                  |     +------+    +-------------+ +------------+  |
                  |     | etcd |    |  scheduler  | | controller |  |
                  |     +------+    +-------------+ |  manager   |  |
                  |                                 +------------+  |
                  +------------------------+------------------------+
                                           |
                                           | (Node Communication)
                                           v
                  +-------------------------------------------------+
                  |                  WORKER NODE                    |
                  |                                                 |
                  |  +--------------------+   +------------------+  |
                  |  |      kubelet       |   |    kube-proxy    |  |
                  |  +---------+----------+   +--------+---------+  |
                  |            |                       |            |
                  |            v                       |            |
                  |  +--------------------+            |            |
                  |  | Container Runtime  |            |            |
                  |  |    (containerd)    |            |            |
                  |  +---------+----------+            |            |
                  |            |                       |            |
                  |            v                       v            |
                  |  +-------------------------------------------+  |
                  |  |                   Pods                    |  |
                  |  +-------------------------------------------+  |
                  +-------------------------------------------------+
```

---

## 3. Control Plane Components

The Control Plane coordinates all cluster operations, maintains desired state, and handles API requests.

### 1. `kube-apiserver` (The Gateway)
- **Role:** Central entry point for all communication into and within the cluster.
- **Function:** Exposes the Kubernetes API (JSON over HTTP/gRPC). Whenever you run a `kubectl` command, or whenever internal controllers communicate, requests are authenticated, authorized, validated, and processed by the API server.

### 2. `etcd` (The Brain's Memory)
- **Role:** Distributed, consistent key-value datastore.
- **Function:** Serves as the single source of truth for the entire cluster. It stores cluster configuration, state data, secrets, configmaps, and metadata of all Kubernetes resources (Pods, Services, Deployments).

### 3. `kube-scheduler` (The Placement Engine)
- **Role:** Workload assigner.
- **Function:** Watches for newly created Pods that have no assigned node. It evaluates resource availability (CPU, memory), affinity/anti-affinity rules, taints, and tolerations to choose the most optimal Worker Node for each Pod.

### 4. `kube-controller-manager` (The State Enforcer)
- **Role:** Continuous reconciliation loop.
- **Function:** Constantly compares the **actual state** of the cluster against the **desired state** defined in your manifests. If a node fails or a pod crashes, controllers (Node Controller, ReplicaSet Controller, Endpoint Controller) take corrective actions to restore the desired state.

---

## 4. Worker Node Components

Worker Nodes provide the compute, memory, storage, and networking environment to run containerized applications.

### 1. `kubelet` (The Node Captain)
- **Role:** Primary node agent running on every worker node.
- **Function:** Communicates directly with the `kube-apiserver`. It receives `PodSpecs`, instructs the container runtime to launch or stop containers, and reports node and pod health back to the control plane.

### 2. `kube-proxy` (The Network Director)
- **Role:** Network proxy and packet director on each node.
- **Function:** Manages IP routing and network packet filtering (via `iptables` or `IPVS`). It implements the Kubernetes Service abstraction, ensuring traffic sent to a Service's virtual IP or NodePort is correctly routed to healthy backend Pods.

### 3. Container Runtime (The Execution Engine)
- **Role:** Software responsible for running containers.
- **Function:** Pulls container images from registries, unpacks them, and manages container execution environments through the Container Runtime Interface (CRI). Examples: `containerd`, `CRI-O`.

### 4. Pod (The Atomic Unit)
- **Role:** Smallest deployable unit in Kubernetes.
- **Function:** Encapsulates one or more containers that share the same network namespace (IP address and port space), storage volumes, and IPC namespace.

---

## 5. How Components Work Together (End-to-End Flow)

When an engineer runs `kubectl apply -f deployment.yaml`:

1. **Submission:** `kubectl` sends an HTTP POST request to `kube-apiserver`.
2. **Storage:** The API server authenticates the request and writes the new Deployment definition into `etcd`.
3. **Reconciliation:** The `kube-controller-manager` detects the new Deployment and creates corresponding Pod objects in pending state.
4. **Scheduling:** The `kube-scheduler` notices the unassigned Pods, evaluates node capacities, selects the best Worker Node, and assigns the Pod to that node via `kube-apiserver`.
5. **Execution:** The `kubelet` on the selected Worker Node discovers the assigned Pod, invokes the **Container Runtime** (`containerd`) to pull the image and launch the container.
6. **Routing:** `kube-proxy` configures networking rules on the node so the new Pod can receive traffic.
7. **Health Reporting:** `kubelet` continuously checks container liveness and reports status back to `kube-apiserver`, which updates `etcd`.
