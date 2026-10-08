# Kubernetes Volumes & Storage Architecture

## 1. Overview
In Kubernetes, container filesystems are ephemeral by default. When a container crashes or is restarted, all modified files are lost. To preserve data, share state between containers, or provide enterprise-grade durability, Kubernetes provides a comprehensive storage architecture ranging from temporary in-pod volumes to dynamic cluster-wide persistent volumes.

---

## 2. Storage Types Deep Dive

### 2.1 `emptyDir`
* **Concept**: An `emptyDir` volume is created when a Pod is assigned to a Node and exists as long as that Pod is running on that Node. All containers in the Pod can read and write to the same files in the `emptyDir` volume.
* **Lifecycle**: Tied directly to the Pod. If the Pod is terminated, deleted, or evicted from the node, data in `emptyDir` is deleted permanently.
* **Medium**: Defaults to the node's backing storage medium (disk, SSD), or can be configured as a memory-backed RAM disk (`medium: Memory`).
* **Common Use Cases**:
  * Scratch space (e.g., sorting algorithms, temporary disk caching).
  * Checkpointing long computations for crash recovery within the same Pod lifecycle.
  * Sidecar pattern: A log collector or content-fetcher container writing files that a web server container serves.

#### Practical Example (`emptydir-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - while true; do echo "$(date) - Message from writer" >> /data/shared.log; sleep 5; done
      volumeMounts:
        - name: shared-storage
          mountPath: /data
    - name: reader
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - sleep 2; tail -f /data/shared.log
      volumeMounts:
        - name: shared-storage
          mountPath: /data
  volumes:
    - name: shared-storage
      emptyDir: {}
```

---

### 2.2 `hostPath`
* **Concept**: A `hostPath` volume mounts a file or directory from the host node's filesystem directly into the Pod.
* **Lifecycle**: Outlives the Pod. If the Pod is deleted and rescheduled onto the *same* node, data remains. However, if rescheduled to a different node, the Pod sees the other node's filesystem (which lacks the data).
* **Security & Production Warnings**:
  * Gives Pods direct access to node root filesystem or Docker socket, which presents significant security risks.
  * Tightly couples workloads to specific nodes, breaking Kubernetes cluster portability.
* **Common Use Cases**:
  * Running node-level agents (e.g., Fluentd, cAdvisor, Promtail) reading `/var/log` or `/var/lib/docker`.
  * Local single-node development (Minikube / Kind).

#### Practical Example (`hostpath-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
    - name: app
      image: nginx:1.27
      volumeMounts:
        - name: host-storage
          mountPath: /data
  volumes:
    - name: host-storage
      hostPath:
        path: /tmp/hostpath-data
        type: DirectoryOrCreate
```

---

### 2.3 `PersistentVolume` (PV)
* **Concept**: A `PersistentVolume` is a storage resource in the cluster provisioned by an administrator or dynamically by a StorageClass. It is a cluster-scoped resource (not tied to any single namespace).
* **Key Specifications**:
  * **Capacity**: Storage size (e.g., `1Gi`, `100Gi`).
  * **Access Modes**:
    * `ReadWriteOnce` (RWO): Can be mounted as read-write by a single Node.
    * `ReadOnlyMany` (ROX): Can be mounted as read-only by multiple Nodes.
    * `ReadWriteMany` (RWX): Can be mounted as read-write by multiple Nodes.
    * `ReadWriteOncePod` (RWOP): Can be mounted as read-write by a single Pod.
  * **Reclaim Policies**:
    * `Retain`: When PVC is deleted, the PV remains intact with its data, moved to `Released` status for manual administrative reclamation.
    * `Delete`: When PVC is deleted, the underlying storage asset (e.g., AWS EBS volume) is automatically destroyed.
    * `Recycle` (Deprecated): Basic scrub (`rm -rf /thevolume/*`) to make it available again.

#### Practical Example (`pv.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /tmp/k8s-static-pv-data
```

---

### 2.4 `PersistentVolumeClaim` (PVC)
* **Concept**: A `PersistentVolumeClaim` is a request for storage by a user/developer. It is a namespace-scoped object.
* **Binding Mechanism**: The control plane monitors new PVCs, matches them against available PVs with compatible storage class, capacity, and access modes, and binds them 1-to-1.
* **Decoupling Role**: Allows application developers to request storage abstractly without needing to know physical cloud volume IDs, SAN LUNs, or node details.

#### Practical Example (`pvc.yaml` & `pod-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: static-storage-demo
spec:
  containers:
    - name: app
      image: nginx:1.27
      volumeMounts:
        - name: storage-vol
          mountPath: /data
  volumes:
    - name: storage-vol
      persistentVolumeClaim:
        claimName: static-pvc
```

---

### 2.5 `StorageClass`
* **Concept**: A `StorageClass` defines different "classes" or profiles of storage offered by the cluster (e.g., "fast-ssd", "standard-hdd", "backup").
* **Attributes**:
  * `provisioner`: The volume plugin/driver responsible for creating the physical volume (e.g., `ebs.csi.aws.com`, `k8s.io/minikube-hostpath`, `pd.csi.storage.gke.io`).
  * `parameters`: Provider-specific settings (e.g., `type: gp3`, `encrypted: "true"`).
  * `volumeBindingMode`:
    * `Immediate`: Volume is provisioned as soon as the PVC is created.
    * `WaitForFirstConsumer`: Delay provisioning and binding until a Pod using the PVC is created (enables topology/AZ-aware provisioning).

---

### 2.6 Dynamic Provisioning vs Static Provisioning

| Feature | Static Provisioning | Dynamic Provisioning |
| :--- | :--- | :--- |
| **Workflow** | Cluster admin pre-creates a pool of PVs manually. | Volumes are created on-demand when a user requests a PVC. |
| **Automation** | Manual intervention required. | 100% automated via CSI / Provisioner. |
| **Efficiency** | Can lead to storage waste if claim sizes don't match PV pool. | Exactly requests required size. |
| **StorageClass** | `storageClassName: ""` or matching manual class. | Specified StorageClass (or cluster default). |
| **Cloud-Native Fit**| Legacy, bare-metal, or specialized host storage. | Standard for modern cloud infrastructure (AWS EBS, GCP PD, Azure Disk). |

#### Dynamic Provisioning Example (`dynamic-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 500Mi
```

---

## 3. Practical Verification Commands

```bash
# 1. Apply static PV and PVC
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

# 2. Check binding status
kubectl get pv static-pv
kubectl get pvc static-pvc

# 3. Mount in a Pod and write data
kubectl apply -f pod-pvc.yaml
kubectl exec static-storage-demo -- sh -c 'echo "Storage test 2026" > /data/test.txt'
kubectl exec static-storage-demo -- cat /data/test.txt

# 4. Verify dynamic provisioning via default StorageClass
kubectl apply -f dynamic-pvc.yaml
kubectl get pvc dynamic-storage-pvc
kubectl get sc
```
