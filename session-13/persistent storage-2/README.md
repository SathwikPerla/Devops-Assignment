# Kubernetes Persistent Storage (PV & PVC)

## What was performed?
* Created a **PersistentVolume (`student-pv`)** backed by the host's `/tmp/student-data`.
* Created a **PersistentVolumeClaim (`student-pvc`)** requesting `500Mi` storage.
* Bound the PVC to the PV.
* Created a **Pod (`storage-demo`)** mounting the PVC at `/data`.
* Tested data persistence across Pod deletion.

---

## Step-by-Step Execution & Results

### 1. Create PersistentVolume (PV)
```bash
kubectl apply -f pv.yaml
kubectl get pv student-pv
```
**Output:**
```text
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS
student-pv   1Gi        RWO            Retain           Available
```

### 2. Create PersistentVolumeClaim (PVC)
```bash
kubectl apply -f pvc.yaml
kubectl get pvc student-pvc
```
**Output:**
```text
NAME          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS
student-pvc   Bound    student-pv   1Gi        RWO
```
> **Note:** `student-pvc` successfully **Bound** to `student-pv`.

### 3. Create Pod
```bash
kubectl apply -f pod.yaml
kubectl get pod storage-demo
```
**Output:**
```text
NAME           READY   STATUS    RESTARTS   AGE
storage-demo   1/1     Running   0          1s
```

### 4. Write Data to the Mounted Volume
```bash
kubectl exec storage-demo -- sh -c 'echo "Kubernetes Storage" > /data/message.txt'
kubectl exec storage-demo -- cat /data/message.txt
```
**Output:**
```text
Kubernetes Storage
```

### 5. Verify Persistence Across Pod Deletion
```bash
# Delete the Pod
kubectl delete pod storage-demo

# Recreate the Pod
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/storage-demo --timeout=60s

# Read the file again
kubectl exec storage-demo -- cat /data/message.txt
```
**Output:**
```text
Kubernetes Storage
```

---

## Why Did The Data Persist?
Unlike `emptyDir` (where storage is tied to the Pod and gets deleted with it), a **PersistentVolume** has an independent lifecycle from the Pod. 

Even when the Pod `storage-demo` was deleted, the PVC (`student-pvc`) and PV (`student-pv`) remained intact and safely stored the data on the underlying disk. When the new Pod was created and claimed the same PVC, it immediately got back all the saved data.
