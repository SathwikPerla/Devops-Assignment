# 04. AWS VPC (Virtual Private Cloud) — Networking & Isolation

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. What is a VPC?
**Amazon Virtual Private Cloud (Amazon VPC)** provisions a logically isolated virtual network within the AWS Cloud dedicated to your account. It grants complete control over network topology, IP address ranges, subnets, route tables, and network gateways.

---

## 2. Core VPC Networking Components

### 1. CIDR Blocks
* Classless Inter-Domain Routing blocks define the IPv4 address range for the VPC (e.g., `10.0.0.0/16` gives $65,536$ private IPs).
* AWS reserves 5 IP addresses per subnet (Network address, VPC router, DNS server, future use, and Broadcast address).

### 2. Subnets
* Partitions of the VPC CIDR tied to a single Availability Zone (AZ).
* **Public Subnet:** Associated with a Route Table pointing `0.0.0.0/0` to an **Internet Gateway (IGW)**.
* **Private Subnet:** Not directly accessible from the internet; routes outbound internet traffic through a **NAT Gateway**.

### 3. Route Tables
* Set of rules (routes) determining where network traffic from subnets or gateways is directed.
* Standard local route: `10.0.0.0/16 -> local`.
* Public route: `0.0.0.0/0 -> igw-xxxxxxxxx`.
* Private route: `0.0.0.0/0 -> nat-xxxxxxxxx`.

### 4. Internet Gateway (IGW)
* Horizontally scaled, redundant VPC component that enables communication between instances in public subnets and the internet (handles IPv4 1-to-1 NAT translation).

### 5. NAT Gateway
* Managed network address translation service residing in a **public subnet**.
* Allows instances in **private subnets** to initiate outbound connections to the internet (e.g., for OS package updates, third-party API calls) while completely preventing unsolicited inbound connections from the internet.

---

## 3. Defense-in-Depth: Security Groups vs Network ACLs

```text
Incoming Internet Traffic
         │
         ▼
┌─────────────────────────┐
│   Network ACL (NACL)    │  Stateless • Subnet Level • Allow & Deny Rules (Numbered Order)
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│     Security Group      │  Stateful • Instance Level • Allow Rules Only (Implicit Deny)
└────────┬────────────────┘
         │
         ▼
    EC2 / Pod
```

| Feature | Security Group | Network ACL (NACL) |
| :--- | :--- | :--- |
| **Operates at** | Instance / ENI level | Subnet boundary |
| **State Tracking**| **Stateful** (Return traffic automatically allowed) | **Stateless** (Return traffic must be explicitly allowed) |
| **Rule Types** | Allow rules only | Allow AND Deny rules |
| **Evaluation** | Evaluates all rules before deciding | Evaluates rules in numbered order (lowest number first) |

---

## 4. Standard 3-Tier VPC Architecture

```text
VPC: 10.0.0.0/16
├── Availability Zone A
│   ├── Public Subnet (10.0.1.0/24)   ──► ALBs, NAT Gateway
│   ├── Private Subnet (10.0.2.0/24)  ──► Backend App Servers / EKS Pods
│   └── Database Subnet (10.0.3.0/24) ──► RDS Multi-AZ Primary
└── Availability Zone B
    ├── Public Subnet (10.0.4.0/24)   ──► Redundant ALBs
    ├── Private Subnet (10.0.5.0/24)  ──► Backend App Servers
    └── Database Subnet (10.0.6.0/24) ──► RDS Multi-AZ Standby
```
