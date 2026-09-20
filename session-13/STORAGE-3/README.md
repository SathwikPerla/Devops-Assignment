# Kubernetes Dynamic Storage Provisioning (StorageClass + PVC)

## What is STORAGE-3?
In **STORAGE-2**, we did **Static Provisioning**: an administrator had to manually create a `PersistentVolume` (`pv.yaml`) before a claim could bind to it.

In **STORAGE-3**, we demonstrate **Dynamic Provisioning**:
* We do **not** write or apply a `pv.yaml`.
* The `PersistentVolumeClaim` requests storage specifying `storageClassName: standard`.
* Kubernetes and the cluster's **StorageClass** dynamically provision the underlying `PersistentVolume` (PV) on-the-fly!

---

## Architecture Flow

```text
PVC (requests 500Mi via StorageClass 'standard')
 │
 ▼
StorageClass (k8s.io/minikube-hostpath)
 │
 ▼
Automatically Provisions PV (pvc-xxxx...)
 │
 ▼
Pod (mounts PVC to /data)
```

---

## Files in this Directory

1. [`pvc.yaml`](pvc.yaml) - Defines `dynamic-pvc` with `storageClassName: standard` and `500Mi` storage request.
2. [`pod.yaml`](pod.yaml) - Defines `dynamic-demo` pod mounting `dynamic-pvc` to `/data`.

---

## Commands & Verification

### 1. Create the Dynamic PVC
```bash
kubectl apply -f pvc.yaml
kubectl get pvc dynamic-pvc
```
**Output:**
```text
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
dynamic-pvc   Bound    pvc-ccfbd1c2-4560-460d-bfdd-ca273e8ff390   500Mi      RWO            standard
```
> Notice: The PV was automatically created and bound immediately without creating a `pv.yaml`!

### 2. Verify the Automatically Created PV
```bash
kubectl get pv
```

### 3. Create and Run the Pod
```bash
kubectl apply -f pod.yaml
kubectl get pod dynamic-demo
```
**Output:**
```text
NAME           READY   STATUS    RESTARTS   AGE
dynamic-demo   1/1     Running   0          1s
```

### 4. Test Writing to the Dynamic Volume
```bash
kubectl exec dynamic-demo -- sh -c 'echo "Dynamic Provisioning with StorageClass" > /data/message.txt'
kubectl exec dynamic-demo -- cat /data/message.txt
```
**Output:**
```text
Dynamic Provisioning with StorageClass
```

### 5. Verify Persistence Across Pod Re-creation
```bash
kubectl delete pod dynamic-demo
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/dynamic-demo --timeout=60s
kubectl exec dynamic-demo -- cat /data/message.txt
```
**Output:**
```text
Dynamic Provisioning with StorageClass
```
The data survived pod deletion!
