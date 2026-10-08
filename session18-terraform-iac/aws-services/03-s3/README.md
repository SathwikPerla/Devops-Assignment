# 03. AWS S3 (Simple Storage Service) — Cloud Object Storage

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. What is S3?
**Amazon Simple Storage Service (Amazon S3)** is an industry-leading object storage service offering 99.999999999% (11 9's) of data durability. Unlike block storage (EBS) or file storage (EFS), S3 stores data as **objects** within **buckets**, accessed over HTTPS via REST APIs.

---

## 2. Core Concepts

### 1. Buckets
* Root logical container for storing objects.
* Names must be **globally unique** across all AWS accounts worldwide and comply with DNS naming conventions (lowercase, 3–63 chars, no underscores).
* Configured in a specific AWS Region (e.g., `ap-south-1`).

### 2. Objects
* Fundamental entities stored in S3 consisting of:
  * **Key:** The unique string path/name of the object (e.g., `images/profile.jpg`).
  * **Value:** The binary payload data (file size: 0 bytes up to 5 TB).
  * **Version ID:** Generated when versioning is enabled.
  * **Metadata:** Key-value pairs describing the object (system metadata like `Content-Type`, plus custom tags).

---

## 3. Storage Classes & Cost Optimization

| Storage Class | Availability | Durability | Min Duration | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **S3 Standard** | 99.99% | 11 9's | None | Frequently accessed web assets, mobile apps, big data |
| **S3 Intelligent-Tiering**| 99.9% | 11 9's | None | Data with unknown or unpredictable access patterns |
| **S3 Standard-IA** | 99.9% | 11 9's | 30 days | Long-term backup, disaster recovery, infrequently accessed data |
| **S3 One Zone-IA** | 99.5% | 11 9's (1 AZ) | 30 days | Secondary backup copies, easily recreatable data |
| **S3 Glacier Instant** | 99.9% | 11 9's | 90 days | Millisecond retrieval for rare quarterly archive queries |
| **S3 Glacier Flexible**| 99.9% | 11 9's | 90 days | Archival data retrievable in minutes to hours |
| **S3 Glacier Deep Archive**| 99.9% | 11 9's | 180 days | Lowest cost storage (7–10 year regulatory compliance) |

---

## 4. Lifecycle Policies & Versioning

### S3 Versioning
* Preserves, retrieves, and restores every version of every object stored in the bucket.
* Protects against unintended user overwrites and accidental deletion.
* A `DELETE` operation creates a **Delete Marker** rather than permanently purging the file until explicitly removed.

### Lifecycle Management
Automates transitions between storage classes and eventual data expiration:
```text
Day 0: Object created in S3 Standard
  │
  ▼ 30 Days
Transition to S3 Standard-IA
  │
  ▼ 90 Days
Transition to S3 Glacier Flexible Archive
  │
  ▼ 365 Days
Permanent Expiration / Deletion
```

---

## 5. Security & Encryption

* **SSE-S3 (AES-256):** Encryption keys handled and managed directly by AWS (zero key management overhead, enabled by default).
* **SSE-KMS (`aws:kms`):** Customer-managed or AWS-managed keys providing audit logs via CloudTrail and granular key permission boundaries.
* **SSE-C:** Encryption with customer-provided keys passed via HTTP headers.
* **Client-Side Encryption:** Data encrypted locally before transmission over the network.
* **Bucket Policies:** JSON resource policies used to enforce HTTPS (`aws:SecureTransport: true`), prevent public access, or grant cross-account read permissions.

---

## 6. Common DevOps Use Cases

* **Terraform Remote State Backend:** Storing `terraform.tfstate` with versioning enabled and DynamoDB state locking.
* **Static Website Hosting:** Hosting Single Page Applications (React, Vue, HTML/CSS) backed by Amazon CloudFront CDN.
* **CI/CD Build Artifact Repository:** Central archive for compiled tarballs, packages, and container image layers.
