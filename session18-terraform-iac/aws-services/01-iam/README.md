# 01. AWS IAM (Identity and Access Management) — Governance & Security

**Author:** Sathwik Perla  
**Roll Number:** 590  
**Email:** perla.24bcs10590@sst.scaler.com  

---

## 1. What is IAM?
**AWS Identity and Access Management (IAM)** is a foundational global AWS service that enables secure control of authentication (who can sign in) and authorization (what permissions they have) across AWS resources. IAM is free of charge and provides centralized access governance.

---

## 2. Core IAM Entities

### 1. IAM Users
* An identity representing a specific human user or system/workload requiring long-term access to AWS.
* Authenticates via **Console Password** (interactive web UI) or **Access Key ID & Secret Access Key** (programmatic CLI/SDK/API access).

### 2. IAM User Groups
* A collection of IAM users.
* Simplifies permission management: attach policies to the group rather than each user individually.
* Examples: `Admins`, `Developers`, `SecurityAuditors`, `DevOpsEngineers`.

### 3. IAM Roles
* An identity that does not have permanent credentials (no password or long-term access keys).
* Assumed dynamically by users, AWS services (e.g., an EC2 instance assuming an S3-access role), or external federated identities (e.g., Okta, Google).
* Uses the **AWS Security Token Service (STS)** to issue temporary security credentials (valid from 15 minutes to 12 hours).

---

## 3. Policies & Permissions

### IAM Policy Structure
Policies are JSON documents defining permissions. The core syntax:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::production-app-data",
        "arn:aws:s3:::production-app-data/*"
      ],
      "Condition": {
        "Bool": { "aws:SecureTransport": "true" }
      }
    }
  ]
}
```

### Policy Types
1. **Identity-Based Policies:** Attached to Users, Groups, or Roles.
   * *AWS Managed:* Maintained by AWS (e.g., `AdministratorAccess`, `ReadOnlyAccess`).
   * *Customer Managed:* Custom JSON tailored to specific organization requirements.
   * *Inline:* Embedded directly inside a single user or role.
2. **Resource-Based Policies:** Attached directly to resources (e.g., S3 Bucket Policies, KMS Key Policies).

---

## 4. The Principle of Least Privilege
* Grant only the absolute minimum permissions necessary to perform a given job function, and nothing more.
* Never grant `*` (wildcard) actions or resources in production environments.
* Periodically audit and trim unused permissions using **IAM Access Analyzer** and **CloudTrail**.

---

## 5. IAM Best Practices

1. **Lock Away the AWS Root Account:** Use Root only for initial account setup and emergency recovery; enable hardware/virtual MFA immediately.
2. **Enforce Multi-Factor Authentication (MFA):** Require MFA for all human user accounts, especially administrative roles.
3. **Use Roles for Applications and EC2:** Never hardcode Access Keys into code or config files. Use IAM Instance Profiles for EC2 and IRSA (IAM Roles for Service Accounts) for EKS/Kubernetes.
4. **Rotate Credentials Regularly:** Establish automated access key rotation policies.
5. **Use Permission Boundaries:** Define maximum allowed permissions for IAM delegates creating new roles.

---

## 6. Common DevOps Use Cases

* **CI/CD Integration:** GitHub Actions / GitLab CI assuming an IAM Role via OpenID Connect (OIDC) without storing static long-lived AWS keys in repo secrets.
* **Microservice Data Access:** Kubernetes pods assuming dedicated IAM roles to access specific DynamoDB tables or S3 buckets.
* **Cross-Account Access:** Centrally managed master identity account delegating role assumption into Dev, Staging, and Production AWS accounts.
