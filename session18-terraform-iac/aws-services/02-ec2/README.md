# 02. AWS EC2 (Elastic Compute Cloud) — Compute Services

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. What is EC2?
**Amazon Elastic Compute Cloud (Amazon EC2)** provides scalable on-demand virtual computing capacity in the AWS cloud. It eliminates upfront hardware investments, allowing developers to provision and configure virtual servers (instances) with custom OS, memory, CPU, and storage within seconds.

---

## 2. Core EC2 Architectural Components

### 1. Amazon Machine Image (AMI)
* A pre-configured template providing the operating system, initial application state, and configuration needed to launch an instance.
* **Types:** AWS-provided (Amazon Linux 2023, Ubuntu, Red Hat, Windows), AWS Marketplace AMIs, and Custom/Private AMIs baked with tools like HashiCorp Packer.

### 2. Instance Types & Families
Categorized by hardware resource ratios:
* **General Purpose (`t3`, `t4g`, `m6i`, `m7g`):** Balanced compute, memory, and networking. Ideal for web servers, dev environments.
* **Compute Optimized (`c6i`, `c7g`):** High ratio of compute performance to memory. Ideal for batch processing, media transcoding, gaming servers.
* **Memory Optimized (`r6i`, `r7g`, `x2idn`):** Fast performance for workloads processing massive in-memory datasets (Redis, Memcached, high-perf databases).
* **Storage Optimized (`i3en`, `d3`):** High sequential read/write access to massive local storage (data warehousing, distributed file systems).
* **Accelerated Computing (`p4d`, `g5`):** Hardware GPU/TPU accelerators for Machine Learning, deep learning training, and 3D rendering.

### 3. Key Pairs
* Cryptographic asymmetric key pair (public key stored on AWS instance, private key `.pem` kept by developer) used for secure SSH access (Linux) or RDP password decryption (Windows).

### 4. Security Groups
* Virtual firewall operating at the **instance network interface (ENI)** level.
* **Stateful:** If inbound traffic is allowed (e.g., port 80), outbound response traffic is automatically allowed regardless of outbound rules.
* Evaluates **allow rules only** (implicit deny-all default for inbound).

### 5. Elastic Block Store (EBS)
* Network-attached persistent block storage volumes independent of instance lifecycle.
* **Volume Types:**
  * `gp3` / `gp2`: General purpose SSD (balanced baseline 3000 IOPS / 125 MB/s).
  * `io2` / `io1`: Provisioned IOPS SSD for latency-critical enterprise databases.
  * `st1`: Throughput optimized HDD for big data, data warehouses, log processing.
  * `sc1`: Cold HDD for rarely accessed sequential workloads.
* Supports automated point-in-time **EBS Snapshots** backed up to S3.

### 6. Public vs Private vs Elastic IP
* **Private IP:** Internal IP address allocated within the VPC subnet CIDR; persists through instance stop/starts.
* **Public IP:** Globally routable address assigned dynamically from AWS public pool; changes when instance stops and starts.
* **Elastic IP (EIP):** Static, persistent public IPv4 address that can be remapped rapidly between instances for failover.

---

## 3. Instance Lifecycle

```text
Launch ──► Pending ──► Running ◄──► Stopping ──► Stopped
                          │                         │
                          ▼                         ▼
                  Shutting-down ───────────► Terminated
```

1. **Pending:** Initial provisioning, host allocation, and AMI decompression.
2. **Running:** Active and operating normally (accessible via SSH/SSM).
3. **Stopping / Stopped:** EBS-backed instances can be stopped (compute charges stop; only EBS storage charges apply).
4. **Terminated:** Permanent deletion; root volume destroyed unless `DeleteOnTermination=false`.

---

## 4. Common DevOps Use Cases

* **Container Hosts:** Provisioning worker nodes for self-managed Kubernetes clusters or Docker Swarm.
* **CI/CD Build Runners:** Self-hosted GitHub Actions runners with custom tooling, caching, and hardware specs.
* **Legacy Monolith Hosting:** Running traditional enterprise applications, ERPs, and internal web servers behind Application Load Balancers.
