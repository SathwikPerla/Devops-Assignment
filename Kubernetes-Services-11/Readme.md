# Session 9 - Kubernetes ClusterIP & Internal Service Discovery

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## Overview

In Kubernetes, Pods are ephemeral and dynamic—their IP addresses change whenever they are restarted, rescheduled, or scaled. A **ClusterIP Service** solves this by providing a single, stable virtual IP address and a consistent DNS name to front a pool of backend pods.

This assignment demonstrates:
1. Deploying a multi-replica Nginx web application behind a selector label (`app=web-clusterip`).
2. Exposing the pods internally using a **ClusterIP** service on port `8080` (routing to target port `80`).
3. Inspecting the automatic creation and mapping of Kubernetes **Endpoints**.
4. Verifying service discovery and internal load balancing from a client pod using:
   - Short DNS Service Name (`web-service-clusterip:8080`)
   - Direct Virtual ClusterIP (`10.96.18.32:8080`)
   - Fully Qualified Domain Name (FQDN: `web-service-clusterip.default.svc.cluster.local:8080`)

---

## 1. Backend Application Pods

A deployment was provisioned to run 3 replicas of an Nginx web server labeled with `app=web-clusterip`.

### Inspection Command
```bash
kubectl get pods -l app=web-clusterip -o wide
```

### Pod Details
| Pod Name | Status | IP Address | Node |
| :--- | :--- | :--- | :--- |
| `web-app-clusterip-89d947d67-4zc5g` | Running | `10.244.0.7` | `desktop-control-plane` |
| `web-app-clusterip-89d947d67-rdvq8` | Running | `10.244.0.5` | `desktop-control-plane` |
| `web-app-clusterip-89d947d67-tjv4t` | Running | `10.244.0.6` | `desktop-control-plane` |

All 3 backend pods are healthy and running with distinct internal overlay IP addresses (`10.244.0.x`).

### Evidence
![Backend Pods Running](<Screenshot 2026-09-18 at 12.17.59 AM.png>)

---

## 2. ClusterIP Service Configuration

A Kubernetes Service manifest of type `ClusterIP` was defined to expose port `8080` externally within the cluster, redirecting traffic to container port `80` on pods matching `app=web-clusterip`.

### Manifest (`service.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-clusterip
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 80
```

### Apply and Verify Service
```bash
kubectl apply -f service.yaml
kubectl get svc web-service-clusterip
```

### Service Details
- **Service Name:** `web-service-clusterip`
- **Type:** `ClusterIP` (Internal only, not reachable outside the cluster)
- **Cluster-IP:** `10.96.18.32` (Stable virtual IP allocated from service CIDR)
- **Port:** `8080/TCP` -> Target Port `80/TCP`

### Evidence
![ClusterIP Service Created](<Screenshot 2026-09-17 at 12.06.18 PM.png>)

---

## 3. Endpoints & Dynamic Pod Tracking

When a Service specifies a label `selector`, the Kubernetes endpoint controller automatically discovers matching pods and registers their private IPs and target ports as **Endpoints** (or **EndpointSlices**).

### Inspection Command
```bash
kubectl get endpoints web-service-clusterip
```

### Observed Endpoints
```text
NAME                    ENDPOINTS                               AGE
web-service-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80   56s
```

All 3 backend pod IPs (`10.244.0.5:80`, `10.244.0.6:80`, `10.244.0.7:80`) are actively registered under `web-service-clusterip`.

### Evidence
![Service Endpoints](<Screenshot 2026-09-17 at 12.06.56 PM.png>)

---

## 4. Client Test Pod (`curl-client`)

To test intra-cluster network connectivity and verify DNS resolution, a lightweight client pod (`curl-client`) was deployed into the cluster.

### Check Client Pod
```bash
kubectl get pod curl-client
```

### Evidence
![Client Pod Status](<Screenshot 2026-09-17 at 12.08.39 PM.png>)

---

## 5. Connectivity & Service Discovery Verification

Using `kubectl exec` inside the `curl-client` pod, we tested three distinct ways to reach the service:

### Method A: Short DNS Service Name
Kubernetes CoreDNS automatically resolves service names within the local namespace:
```bash
kubectl exec -it curl-client -- curl -s http://web-service-clusterip:8080
```
- **Result:** Successfully returned `<h1>Welcome to nginx!</h1>`.
- **Mechanism:** CoreDNS mapped `web-service-clusterip` to ClusterIP `10.96.18.32`, and `kube-proxy` routed the request to one of the backend pods on port 80.

![Access via Short DNS Name](<Screenshot 2026-09-17 at 12.11.05 PM.png>)

---

### Method B: Virtual ClusterIP Address
Directly querying the virtual ClusterIP assigned to the service:
```bash
kubectl exec -it curl-client -- curl -s http://10.96.18.32:8080
```
- **Result:** Successfully returned `<h1>Welcome to nginx!</h1>`.
- **Mechanism:** Direct TCP connection to `10.96.18.32:8080`, translated and load-balanced via `iptables`/`ipvs` rules managed by `kube-proxy`.

![Access via ClusterIP Address](<Screenshot 2026-09-17 at 12.13.51 PM.png>)

---

### Method C: Fully Qualified Domain Name (FQDN)
Querying using the full DNS hierarchy (`<service-name>.<namespace>.svc.cluster.local`):
```bash
kubectl exec -it curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080
```
- **Result:** Successfully returned `<h1>Welcome to nginx!</h1>`.
- **Mechanism:** Resolves across namespaces within the Kubernetes cluster domain hierarchy, confirming cross-namespace addressability.

![Access via FQDN](<Screenshot 2026-09-17 at 12.14.13 PM.png>)

---

## Key Notes & Concepts Learned

1. **Why ClusterIP is Needed:**
   - Pods are ephemeral; scaling up/down or recreating a pod assigns a new IP address.
   - ClusterIP provides a persistent IP and DNS entry that remains constant throughout the service lifecycle.
2. **Port vs TargetPort:**
   - `port (8080)`: The port exposed internally inside the cluster on the service's ClusterIP.
   - `targetPort (80)`: The port on the underlying container that receives the forwarded traffic.
3. **CoreDNS & Service Discovery:**
   - Pods automatically inherit cluster DNS search domains (`default.svc.cluster.local`, `svc.cluster.local`, `cluster.local`).
   - Allows communicating via simple service names without hardcoding IP addresses.
4. **Endpoints Controller:**
   - Bridges Services and Pods dynamically based on label selectors. Without healthy matching pods, endpoints remain empty and traffic drops.





---




# Task 2: NodePort Service

Exposing the Nginx web application externally using a Kubernetes NodePort service on static port `30080`.

### 1. Deploy Backend Pods
```bash
kubectl apply -f 02-nodeport/app-deployment.yaml
kubectl get pods -l app=web-nodeport -o wide
```

![alt text](<Screenshot 2026-09-18 at 1.26.43 AM.png>)

---

### 2. Create NodePort Service
```bash
kubectl apply -f 02-nodeport/service.yaml
kubectl get svc web-service-nodeport
```

![alt text](<Screenshot 2026-09-18 at 1.26.56 AM.png>)

---

### 3. Verify Service Endpoints
```bash
kubectl get endpoints web-service-nodeport
```

![alt text](<Screenshot 2026-09-18 at 1.27.58 AM.png>)

---

### 4. Access Application via Curl
On macOS (Docker Desktop), forward the service port to `localhost:30080`:
```bash
# In a separate terminal tab or background:
kubectl port-forward svc/web-service-nodeport 30080:80
```
Then run the curl command:
```bash
curl -i http://localhost:30080
```
*(Alternatively, query the node IP directly via the test client pod: `kubectl exec -it curl-client -- curl -i http://172.23.0.2:30080`)*

![alt text](<Screenshot 2026-09-18 at 1.45.57 AM.png>)



---

### 5. Access Application via Browser
With `kubectl port-forward` running, open `http://localhost:30080` in your web browser:

![alt text](<Screenshot 2026-09-18 at 1.45.27 AM.png>)







# Task 3: LoadBalancer Service

Exposing the Nginx web application using a Kubernetes LoadBalancer service. In Docker Desktop, this automatically binds to `localhost:80`.

### 1. Deploy Backend Pods
```bash
kubectl apply -f 03-loadbalancer/app-deployment.yaml
kubectl get pods -l app=web-loadbalancer -o wide
```

![alt text](<Screenshot 2026-09-18 at 3.51.28 AM.png>)

---

### 2. Create LoadBalancer Service
```bash
kubectl apply -f 03-loadbalancer/service.yaml
kubectl get svc web-service-loadbalancer
```

![alt text](<Screenshot 2026-09-18 at 4.02.42 AM.png>)

---

### 3. Access Application via Curl
In Docker Desktop on macOS, the LoadBalancer automatically routes to `localhost`:
```bash
curl -i http://localhost
```

![alt text](<Screenshot 2026-09-18 at 4.03.17 AM.png>)

---

### 4. Access Application via Browser
Accessing `http://localhost` from your web browser:

![alt text](<Screenshot 2026-09-18 at 4.03.30 AM.png>)

---

### 5. Production & Cloud Cost Considerations
- **Cost:** Every cloud LoadBalancer (AWS NLB/ALB, GCP LB) provisions dedicated infrastructure costing ~$18–$25/month per service.
- **Best Practice:** Use a single LoadBalancer service for an Ingress Controller, and route traffic to multiple internal ClusterIP services via Ingress path/host rules to avoid redundant load balancer costs.

---

### Cleanup
```bash
kubectl delete -f 03-loadbalancer/service.yaml
kubectl delete -f 03-loadbalancer/app-deployment.yaml
```

---

# Task 4: ExternalName Service

Mapping an external DNS name (`api.github.com`) to an internal Kubernetes service name using `type: ExternalName`.

### 1. Create ExternalName Service
```bash
kubectl apply -f 04-externalname/service.yaml
kubectl get svc external-database-service
```
> Notice that `CLUSTER-IP` is `<none>` and `EXTERNAL-IP` is `api.github.com`.

![alt text](<Screenshot 2026-09-18 at 4.08.38 AM.png>)

---

### 2. Deploy DNS Test Client Pod
```bash
kubectl apply -f 04-externalname/client-pod.yaml
kubectl get pod dns-test-client
```

![alt text](<Screenshot 2026-09-18 at 4.09.05 AM.png>)

---

### 3. Verify DNS CNAME Resolution
Verify that CoreDNS returns a CNAME pointing to `api.github.com`:
```bash
kubectl exec -it dns-test-client -- nslookup external-database-service
```

![alt text](<Screenshot 2026-09-18 at 4.09.27 AM.png>)

---

### 4. Test HTTP Request to External Endpoint
Send a request through the internal service name with the `Host` header:
```bash
kubectl exec -it dns-test-client -- curl -s -k -H "Host: api.github.com" https://external-database-service
```

![alt text](<Screenshot 2026-09-18 at 4.09.57 AM.png>)

---

### 5. Key Caveats & Production Considerations
- **DNS Level Only:** ExternalName creates a CNAME record in CoreDNS; it does not proxy traffic or remap ports.
- **TLS/SNI Mismatch:** When calling HTTPS endpoints via ExternalName, pass the external `Host` header or bypass strict host checking (`-k`) because the server certificate matches the external domain.
- **DNS Names Only:** Requires a hostname (e.g., `api.github.com`), not a raw IP address.

---

### Cleanup
```bash
kubectl delete -f 04-externalname/client-pod.yaml
kubectl delete -f 04-externalname/service.yaml
```

---

# Task 5: Headless Service

A **Headless Service** (`clusterIP: None`) provides direct DNS resolution to individual Pod IPs without assigning a virtual ClusterIP or performing proxy-based load balancing. It is designed for **StatefulSets** (e.g., Kafka, Redis, MongoDB, ZooKeeper).

### 1. Create Headless Service
```bash
kubectl apply -f 05-headless/service.yaml
kubectl get svc web-service-headless
```
> Notice that `CLUSTER-IP` is explicitly `None`.

![alt text](<Screenshot 2026-09-18 at 4.14.17 AM.png>)

---

### 2. Deploy StatefulSet
```bash
kubectl apply -f 05-headless/app-statefulset.yaml
kubectl get pods -l app=web-headless -o wide
```

![alt text](<Screenshot 2026-09-18 at 4.14.47 AM.png>)

---

### 3. Deploy DNS Test Client Pod
```bash
kubectl apply -f 05-headless/client-pod.yaml
kubectl get pod headless-dns-client
```

![alt text](<Screenshot 2026-09-18 at 4.15.04 AM.png>)

---

### 4. Verify DNS Lookup on Service Name (Returns ALL Pod IPs)
```bash
kubectl exec -it headless-dns-client -- nslookup web-service-headless
```
CoreDNS returns the individual IP of every backend pod instead of a single virtual IP.

![alt text](<Screenshot 2026-09-18 at 4.15.19 AM.png>)

---

### 5. Verify Direct DNS Lookup & Curl for a Specific Pod
Query and access `web-stateful-0` directly using its unique pod DNS record:
```bash
kubectl exec -it headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
kubectl exec -it headless-dns-client -- curl -s http://web-stateful-0.web-service-headless:80
```

![alt text](<Screenshot 2026-09-18 at 4.15.54 AM.png>)

---

## Kubernetes Services Summary & Comparison

| Service Type | Cluster-IP | Node Port | External Access | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **ClusterIP** | Yes (Virtual IP) | No | Internal only | Default; internal microservice-to-microservice traffic |
| **NodePort** | Yes | Yes (`30000-32767`) | Node IP + Port | Direct node access, bare-metal clusters, dev testing |
| **LoadBalancer** | Yes | Yes | Cloud Load Balancer | Public internet-facing production services (AWS/GCP/Azure) |
| **ExternalName**| No (`<none>`) | No | CNAME alias | Internal DNS alias to external third-party APIs/databases |
| **Headless** | No (`None`) | No | Direct Pod DNS | Stateful distributed workloads (Kafka, Redis, Mongo, ZooKeeper) |

---

### Cleanup
```bash
kubectl delete -f 05-headless/client-pod.yaml
kubectl delete -f 05-headless/app-statefulset.yaml
kubectl delete -f 05-headless/service.yaml
```
