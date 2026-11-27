# Project 05 – Terraform Production Incident Management

[![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.10.0-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)

A complete, production-grade hands-on laboratory covering **advanced Terraform operations, incident response, drift detection, resource import, refactoring with moved blocks, and disaster recovery** in **`ap-southeast-1` (Singapore)**.

---

## The 5 Production Incident Labs

| Lab | Topic | Focus Area |
|---|---|---|
| **[Lab 01](./labs/01-drift-detection/README.md)** | **Drift Detection & Remediation** | Identifying out-of-band AWS Console changes with `terraform plan -refresh-only` and safe reconciliation. |
| **[Lab 02](./labs/02-resource-import/README.md)** | **Resource Import** | Modern Terraform 1.5+ declarative `import {}` blocks bringing unmanaged AWS resources into state without recreation. |
| **[Lab 03](./labs/03-refactoring-moved-block/README.md)** | **Refactoring with `moved` Blocks** | Transitioning monolithic resources into reusable modules without destroying live production servers. |
| **[Lab 04](./labs/04-state-recovery/README.md)** | **Disaster Recovery** | Restoring corrupted or lost state using Amazon S3 bucket version history, lineage, and serial numbers. |
| **[Lab 05](./labs/05-resource-replacement/README.md)** | **Controlled Resource Replacement** | Replacing unhealthy EC2 instances safely using `terraform apply -replace` and `create_before_destroy`. |

---

## Project Structure

```text
terraform-project-05/
│
├── bootstrap/                       # Provisions the S3 remote state bucket with versioning & encryption
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── environments/
│   └── dev/                         # Development lab environment with native S3 locking (use_lockfile = true)
│       ├── versions.tf
│       ├── provider.tf
│       ├── backend.tf
│       ├── main.tf                  # Target resources for Labs (Security Group, test resources)
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
├── modules/
│   └── ec2/                         # Hardened EC2 module with dynamic AMI lookup for ap-southeast-1
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── labs/                            # Comprehensive scenario runbooks for each of the 5 incidents
│   ├── 01-drift-detection/
│   ├── 02-resource-import/
│   ├── 03-refactoring-moved-block/
│   ├── 04-state-recovery/
│   └── 05-resource-replacement/
│
├── scripts/                         # Automated preflight & resource verification scripts
│   ├── preflight-check.sh / .ps1
│   └── verify-resources.sh
│
├── docs/                            # Deep-dive architecture, incident runbooks, and interview questions
│   ├── architecture.md
│   ├── incident-runbooks.md
│   ├── troubleshooting.md
│   └── interview-questions.md
│
└── README.md
```
