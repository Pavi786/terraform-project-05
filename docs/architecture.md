# Project 05 Architecture & Design Specification

## Overview
Project 05 is built specifically for **production troubleshooting, disaster recovery, and incident response** in **`ap-southeast-1` (Singapore)**.

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      AWS AP-SOUTHEAST-1 (SINGAPORE)                    │
 └────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
                 ┌──────────────────┴──────────────────┐
                 ▼                                     ▼
      ┌───────────────────────┐             ┌─────────────────────┐
      │  Bootstrap S3 Bucket  │             │   Target VPC (Dev)  │
      │  (p05-tfstate-...)    │             │  • Isolated Subnets │
      ├───────────────────────┤             └──────────┬──────────┘
      │ • Versioning Enabled  │                        │
      │ • AES256 Encryption   │                        ▼
      │ • Public Blocked      │             ┌─────────────────────┐
      │ • use_lockfile = true │             │    Lab Resources    │
      └───────────────────────┘             ├─────────────────────┤
                                            │ • Lab 1: App SG     │
                                            │ • Lab 2: SQS Queue  │
                                            │ • Lab 3: Moved EC2  │
                                            │ • Lab 4: DR State   │
                                            │ • Lab 5: Replace EC2│
                                            └─────────────────────┘
```

## State Locking Architecture: Native S3 Locking (`use_lockfile = true`)
Historically, Terraform on AWS required a separate Amazon DynamoDB table with a `LockID` string attribute to prevent two engineers from running `apply` concurrently.

Starting in **Terraform 1.10+**, HashiCorp added native state locking directly to the Amazon S3 backend:
```hcl
terraform {
  backend "s3" {
    bucket       = "p05-tfstate-352458843311-ap-southeast-1"
    key          = "environments/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true   # Native S3 concurrency locking!
  }
}
```
When enabled, Terraform uses S3 Object Conditional Writes (`If-None-Match` HTTP headers) to create an atomic lockfile (`.terraform.tfstate.lock.info`) directly in the S3 bucket without needing DynamoDB!
