# 05. AWS Database Services — DynamoDB & RDS

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## Part 1: Amazon DynamoDB (Serverless NoSQL)

### 1. What is DynamoDB?
**Amazon DynamoDB** is a fully managed, serverless, key-value and document NoSQL database designed for single-digit millisecond latency at any scale. It features automatic horizontal sharding, built-in security, backup, and in-memory caching via DynamoDB Accelerator (DAX).

### 2. Core Data Modeling Concepts
* **Tables:** Logical collection of data items (schema-less; no upfront column definitions except the primary key).
* **Items:** A group of attributes uniquely identifiable among all other items (analogous to a row in relational databases, max item size: 400 KB).
* **Attributes:** Fundamental data elements (analogous to columns/fields, supporting scalars, sets, and nested JSON documents).

### 3. Primary Key Strategies
1. **Simple Primary Key (Partition Key):**
   * Uses a single attribute (the *Partition Key* / Hash key).
   * Determines the internal physical partition where the item is stored via an internal hash function.
   * *Example:* `UserID` $\rightarrow$ Item lookup.
2. **Composite Primary Key (Partition Key + Sort Key):**
   * Combines a *Partition Key* (Hash) and a *Sort Key* (Range).
   * Items with the same partition key are stored together in sorted order by sort key.
   * *Example:* `PartitionKey: CustomerID`, `SortKey: OrderDate`.

### 4. DynamoDB Use Cases
* **Terraform State Locking:** Managing concurrent lock IDs (`LockID`) to prevent race conditions during `terraform apply`.
* **User Session Management:** Web session state storage with automated Time-To-Live (TTL) record expiration.
* **IoT & Telemetry Ingestion:** High-velocity write workloads with millisecond response time SLAs.

---

## Part 2: Amazon RDS (Relational Database Service)

### 1. What is Amazon RDS?
**Amazon Relational Database Service (Amazon RDS)** automates the setup, operation, and scaling of relational databases in the cloud. It abstracts away routine administrative tasks (hardware provisioning, database setup, patching, automated backups) while allowing users to utilize standard SQL engines.

### 2. Supported Database Engines
* **Amazon Aurora:** Cloud-native relational database (MySQL & PostgreSQL compatible) with up to 5x higher throughput.
* **PostgreSQL**
* **MySQL**
* **MariaDB**
* **Oracle Database**
* **Microsoft SQL Server**

### 3. Database Instances & Storage
* Dedicated virtual server instances configured with vCPU and memory.
* Storage provided by EBS volumes (`gp3` or provisioned `io2` SSDs) with auto-scaling storage capability.

### 4. Security Architecture
* Placed in dedicated **Private DB Subnet Groups** spanning at least two Availability Zones (never exposed to public internet).
* Controlled via **Security Groups** allowing inbound traffic only from application backend tier instances.
* Data-at-rest encrypted via **AWS KMS**; data-in-transit secured via TLS/SSL.

### 5. High Availability (Multi-AZ) vs Read Replicas

```text
       Write Traffic ──► [Primary DB (AZ-A)] ───Synchronous Replication───► [Standby DB (AZ-B)]
                                │                                            (Multi-AZ Failover)
                                │ Asynchronous
                                ▼ Replication
                         [Read Replica 1] ──► Read Traffic
```

| Feature | Multi-AZ Deployment | Read Replicas |
| :--- | :--- | :--- |
| **Primary Purpose** | **High Availability & Disaster Recovery** | **Scalability & Performance Optimization** |
| **Replication Type**| **Synchronous** | **Asynchronous** |
| **Standby Access** | Inactive (cannot be queried directly) | Active (serves read-only queries) |
| **Failover** | **Automatic** (DNS failover in 60–120s) | Manual promotion to primary |

### 6. Automated Backups & Snapshots
* Automated daily full backups combined with transaction logs allow point-in-time recovery (PITR) down to the exact second within a retention window (1–35 days).

### 7. RDS Use Cases
* **Transactional Business Applications:** E-commerce carts, payment processing, inventory reconciliation requiring strict ACID compliance.
* **Complex Analytical Queries:** Relational schemas with multi-table joins and foreign key constraints.
