# 🏗️ Project 05 — Terraform Production Incident Management

### 📋 Complete Single-File Reference (All 28 Files)

> **☁️ Cloud:** AWS `ap-southeast-1` (Singapore)
> **🔧 Terraform:** `>= 1.10.0` with Native S3 State Locking (`use_lockfile = true`)
> **🔐 Backend:** Amazon S3 — Versioned, Encrypted, Public-Access Blocked
> **📂 Files Included:** 28 files from 8 directories

---

## 🗂️ Table of Contents

| # | Section | What It Does (Layman) |
|---|---------|----------------------|
| 🧱 **Part 1** | [Bootstrap — S3 Remote State Bucket](#-part-1--bootstrap--create-the-s3-remote-state-bucket) | Creates the "safe vault" in AWS where Terraform remembers everything it built |
| 🌍 **Part 2** | [Dev Environment — Provider & Backend](#-part-2--dev-environment--connect-to-aws--store-state) | Tells Terraform "which AWS account to use" and "where to save your memory" |
| 🛡️ **Part 3** | [Dev Environment — Main Resources](#-part-3--dev-environment--the-actual-infrastructure-code) | The real AWS resources we create (Security Groups, VPC lookups) |
| 🖥️ **Part 4** | [EC2 Reusable Module](#-part-4--ec2-reusable-module--a-server-blueprint-you-can-reuse) | A plug-and-play server template — like a cookie cutter for EC2 instances |
| 🔬 **Part 5** | [Lab 01 — Drift Detection](#-part-5--lab-01--drift-detection--someone-changed-aws-behind-your-back) | Someone secretly changed your cloud — how do you catch them? |
| 📥 **Part 6** | [Lab 02 — Resource Import](#-part-6--lab-02--resource-import--bring-a-rogue-resource-under-control) | A resource was created manually — how do you bring it under Terraform? |
| 🔀 **Part 7** | [Lab 03 — Refactoring with Moved Blocks](#-part-7--lab-03--refactoring--reorganize-without-destroying) | Reorganize your code into modules without destroying live servers |
| 🆘 **Part 8** | [Lab 04 — State Disaster Recovery](#-part-8--lab-04--disaster-recovery--your-state-file-is-corrupted) | Your state file is corrupted — how do you recover without losing everything? |
| 🔄 **Part 9** | [Lab 05 — Safe Resource Replacement](#-part-9--lab-05--safe-replacement--swap-a-sick-server-cleanly) | A server is sick — how do you swap it cleanly without breaking things? |
| 📚 **Part 10** | [Documentation — Architecture, Runbooks, Troubleshooting, Interview Q&A](#-part-10--documentation) | Reference guides, quick-action runbooks, common errors, and interview prep |
| 🧰 **Part 11** | [Scripts — Preflight & Verification](#-part-11--scripts--automated-checks) | Automated scripts to validate everything before and after deployment |
| 🚫 **Part 12** | [.gitignore](#-part-12--gitignore--what-git-should-never-track) | Keeps secrets, state files, and junk out of your Git repository |

---

---

# 🧱 Part 1 — Bootstrap: Create the S3 Remote State Bucket

> **🧑‍🍳 Layman Explanation:**
> Before you start building a house, you need a **safe vault** to store your building blueprints.
> This bootstrap module creates an S3 bucket in AWS that acts as Terraform's **memory bank**.
> Every time Terraform creates, changes, or destroys something, it writes it down here.
> Without this, Terraform would forget everything the moment you close your laptop!

---

### 📄 `bootstrap/main.tf`

> *This is the main file. It creates the S3 bucket with three security layers:*
> *1. **Versioning** — Keeps every old copy of the state (like Google Docs version history)*
> *2. **Encryption** — Locks the data so nobody can read it without permission*
> *3. **Public Access Block** — Ensures nobody on the internet can see your state*

```hcl
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-project-05"
      Component   = "Backend-Bootstrap"
      ManagedBy   = "Terraform"
      Environment = "shared-tools"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Globally unique state bucket name adhering to AWS S3 naming rules
  bucket_name = "p05-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

# -----------------------------------------------------------------------------
# Remote State S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket        = local.bucket_name
  force_destroy = true # Set to true for lab demo: Allows clean terraform destroy without BucketNotEmpty error

  lifecycle {
    prevent_destroy = false # Set to true in production
  }

  tags = {
    Name        = local.bucket_name
    Purpose     = "Terraform-Remote-State"
    Environment = "shared-tools"
  }
}

# 1. Versioning: Mandatory for state history, auditing, and Disaster Recovery (Lab 04)
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Server-Side Encryption: Enforce AES256 encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# 3. Public Access Block: Completely seal the bucket from public exposure
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### 📄 `bootstrap/variables.tf`

> *Just one variable — which AWS region to use. Default is Singapore.*

```hcl
variable "aws_region" {
  description = "Target AWS region for Project 05"
  type        = string
  default     = "ap-southeast-1"
}
```

---

### 📄 `bootstrap/outputs.tf`

> *After bootstrap finishes, it prints out:*
> *1. The bucket name it created*
> *2. A ready-to-paste backend configuration snippet for the dev environment*

```hcl
output "state_bucket_name" {
  description = "Name of the created S3 bucket for Terraform remote state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "aws_region" {
  description = "AWS Region of the state bucket"
  value       = var.aws_region
}

output "backend_config_snippet" {
  description = "Backend configuration snippet for environments/dev/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.tf_state.bucket}"
        key          = "environments/dev/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        use_lockfile = true
      }
    }
  EOT
}
```

---

---

# 🌍 Part 2 — Dev Environment: Connect to AWS & Store State

> **🧑‍🍳 Layman Explanation:**
> If the bootstrap was creating the vault, this part is **giving Terraform the keys to the vault and the building site**.
> - `versions.tf` = "What version of tools do we need?"
> - `provider.tf` = "Which AWS account and region are we working in?"
> - `backend.tf` = "Where do we save our memory (state)?"
> - `variables.tf` = "What settings can I customize?"
> - `outputs.tf` = "What info do I want printed after deployment?"
> - `terraform.tfvars.example` = "Here's a sample of what to fill in"

---

### 📄 `environments/dev/versions.tf`

> *Specifies the minimum Terraform version and the AWS provider version needed.*

```hcl
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}
```

---

### 📄 `environments/dev/provider.tf`

> *Tells Terraform: "Connect to AWS in Singapore, and stamp every resource with these tags."*

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Lab         = "terraform-project-05"
    }
  }
}
```

---

### 📄 `environments/dev/backend.tf`

> *This is the connection to our safe vault (S3 bucket) created in the bootstrap step.*
> *`use_lockfile = true` is Terraform 1.10's game-changer — it uses S3's native locking*
> *instead of needing a separate DynamoDB table. Think of it as an automatic "Do Not Disturb"*
> *sign that prevents two people from modifying state at the same time.*

```hcl
# Remote S3 Backend with Native S3 Locking (Terraform 1.10+)
# Notice: 'use_lockfile = true' enables native S3 concurrency locking without needing DynamoDB!
terraform {
  backend "s3" {
    # Replace with the output from bootstrap/outputs.tf after bootstrap apply:
    # bucket       = "p05-tfstate-352458843311-ap-southeast-1"
    # key          = "environments/dev/terraform.tfstate"
    # region       = "ap-southeast-1"
    # encrypt      = true
    # use_lockfile = true
  }
}
```

---

### 📄 `environments/dev/variables.tf`

> *All the knobs and dials you can turn to customize the deployment.*

```hcl
variable "aws_region" {
  description = "Target AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "p05-incident-mgmt"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "allowed_test_cidr" {
  description = "Restricted test CIDR block for Lab 1 (Drift Detection). Never use 0.0.0.0/0 in production."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "Optional VPC ID. If null, the default VPC is used."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance size for Lab 3 and Lab 5"
  type        = string
  default     = "t3.micro"
}
```

---

### 📄 `environments/dev/outputs.tf`

> *After `terraform apply`, these values are printed on screen — like a receipt.*

```hcl
output "aws_account_id" {
  description = "Target AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Target AWS Region"
  value       = var.aws_region
}

output "security_group_id" {
  description = "ID of the Lab 1 Security Group"
  value       = aws_security_group.app_sg.id
}

output "security_group_name" {
  description = "Name of the Lab 1 Security Group"
  value       = aws_security_group.app_sg.name
}

output "security_group_vpc_id" {
  description = "VPC ID where the Security Group is deployed"
  value       = data.aws_vpc.default.id
}
```

---

### 📄 `environments/dev/terraform.tfvars.example`

> *Copy this file as `terraform.tfvars` and customize the values for your environment.*

```hcl
aws_region        = "ap-southeast-1"
project_name      = "p05-incident-mgmt"
environment       = "dev"
allowed_test_cidr = "10.0.0.0/16"
instance_type     = "t3.micro"
```

---

---

# 🛡️ Part 3 — Dev Environment: The Actual Infrastructure Code

> **🧑‍🍳 Layman Explanation:**
> This is the heart of the project. It says:
> 1. "Find the default VPC in this AWS account" (the VPC is like the neighbourhood where our resources live)
> 2. "Create a Security Group that only allows HTTPS traffic from our internal network"
>
> Think of a Security Group as a **bouncer at a nightclub door**:
> - ✅ Port 443 (HTTPS) from `10.0.0.0/16` → "You're on the guest list, come in"
> - ❌ Port 22 (SSH) from anywhere → "Not on the list, go away"
> - ❌ `0.0.0.0/0` (the entire internet) → "Absolutely not"

---

### 📄 `environments/dev/main.tf`

```hcl
data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = var.vpc_id == null ? true : false
  id      = var.vpc_id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# LAB 1: DRIFT DETECTION TARGET RESOURCE
# =============================================================================
# A secure, isolated Security Group allowing HTTPS (Port 443) only from a
# restricted test CIDR block (default: 10.0.0.0/16).
# Notice: No SSH (Port 22) and NO 0.0.0.0/0 open to the world!
# =============================================================================
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "Managed Security Group for Lab 01 - Drift Detection"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTPS from internal test CIDR only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_test_cidr]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-app-sg"
    Lab         = "01-drift-detection"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}
```

---

---

# 🖥️ Part 4 — EC2 Reusable Module: A Server Blueprint You Can Reuse

> **🧑‍🍳 Layman Explanation:**
> Instead of writing the same EC2 server code over and over for each lab, we created a
> **reusable module** — like a cookie cutter. Every time we need a server, we just call this
> module and pass in a few settings (name, size, subnet).
>
> This module also includes smart features:
> - 🧠 **Dynamic AMI Discovery** — It automatically finds the latest Amazon Linux 2023 image
>   instead of hardcoding an AMI ID that might expire or not exist in your region.
> - 🔒 **IMDSv2 Enforced** — Blocks an old, insecure method of stealing credentials from inside the server.
> - 🔐 **Encrypted Root Disk** — All data at rest on the server's hard drive is encrypted.

---

### 📄 `modules/ec2/versions.tf`

```hcl
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}
```

---

### 📄 `modules/ec2/main.tf`

```hcl
# Dynamic AMI Discovery for the selected region (ap-southeast-1)
# Ensures the AMI is always valid and never hardcoded!
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = false # Safety: Keep in private/internal posture

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforce IMDSv2 (Security Best Practice)
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
```

---

### 📄 `modules/ec2/variables.tf`

```hcl
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "p05-app-server"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups associated with the instance"
  type        = list(string)
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

---

### 📄 `modules/ec2/outputs.tf`

```hcl
output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.this.id
}

output "arn" {
  description = "ARN of the created EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}
```

---

---

# 🔬 Part 5 — Lab 01: Drift Detection (Someone Changed AWS Behind Your Back!)

> **🧑‍🍳 Layman Explanation:**
> Imagine you drew the blueprint of your house and filed it in the town office.
> One weekend, a contractor comes and punches a hole in the wall without telling anyone.
> Now the **actual building** doesn't match the **blueprint on file**.
>
> That mismatch is called **"Drift"**.
>
> - `terraform plan -refresh-only` = Sending an inspector to compare the building against the blueprint
> - `terraform apply` = Sending the builder to fix the wall back to blueprint specs
> - `terraform apply -refresh-only` = Rewriting the blueprint to accept the hole as official

---

### 📄 `labs/01-drift-detection/README.md`

```markdown
# Lab 01 – Infrastructure Drift Detection & Remediation

## 1. Real-World Production Incident
**Incident Ticket #INC-9481:**
*Severity:* P1 - Security Compliance Violation
*Summary:* An on-call engineer troubleshooting an off-hours connectivity alert manually opened inbound rules directly inside the AWS Console. Two days later, an automated security audit flagged that an internal database/application port was left wide open to unapproved CIDRs. When a colleague attempted to run a planned Terraform release, unexpected drift was detected.

---

## 2. Architecture & Concept
```
```text
  [Approved IaC Code]               [Terraform State]               [Real AWS World]
   (environments/dev)             (S3 Remote Backend)              (ap-southeast-1)
           │                               │                              │
           │                               │                              │
    Port 443 only                   Port 443 only               Manual Console Edit:
   (from 10.0.0.0/16)              (from 10.0.0.0/16)          [Port 443 from 10.0.0.0/16]
           │                               │           + [Unapproved Port 8080/443]
           │                               │                              │
           └───────────────────────────────┼──────────────────────────────┘
                                           │
                                           ▼
                             `terraform plan -refresh-only`
                                  (Detects the Drift)
```
```markdown

---

## 3. Layman Explanation
Imagine a company's building blueprint (Terraform code). The building manager keeps a copy of the blueprint in the archive (State file). One weekend, a maintenance worker punches a hole in the wall to run a temporary cable, but forgets to tell anyone.
- **Drift** is the difference between the blueprint and the actual building.
- `terraform plan -refresh-only` is like sending an inspector with a clipboard to look at the physical building and compare it with the state file without touching or demolishing anything.
- If you run `terraform apply`, Terraform repairs the wall back to blueprint specifications.
- If you run `terraform apply -refresh-only`, Terraform updates the blueprint to say "the hole is officially accepted".

---

## 4. Terraform Code Walkthrough
File: `environments/dev/main.tf`

resource "aws_security_group" "app_sg" — Only Port 443 from 10.0.0.0/16
- Restricts ingress to port 443 from internal CIDR
- Does NOT open SSH (Port 22) or 0.0.0.0/0 inbound
- Controlled test target for safe drift simulation

---

## 5. Exact Terminal Commands & Execution Sequence

### Phase A: Deploy the Baseline Infrastructure
  cd environments/dev
  terraform init
  terraform plan -out=tfplan
  terraform apply tfplan

### Phase B: Simulate the Incident (Manual Out-of-band Change)
1. Open AWS Console > VPC > Security Groups in ap-southeast-1
2. Find the Security Group: p05-incident-mgmt-dev-app-sg
3. Click Edit inbound rules
4. Add rule: Type=HTTPS(443), Source=192.168.100.0/24, Description="Manual emergency change"
5. Save rules

### Phase C: Detect the Drift
  terraform plan -refresh-only

Expected Output:
  Note: Objects have changed outside of Terraform
  ~ ingress = [ + { cidr_blocks = ["192.168.100.0/24"] ... } ]

### Phase D: Remediation Option 1 — Revert AWS to Approved Code
  terraform plan
  terraform apply
Result: Terraform removes the unauthorized 192.168.100.0/24 rule!

### Phase E: Remediation Option 2 — Accept the Manual Change
  terraform apply -refresh-only
Warning: You must also update .tf code, otherwise next terraform apply reverts it!

---

## 6. Interview Questions & Expert Answers

Q1: What is the difference between terraform plan and terraform plan -refresh-only?
Answer: terraform plan proposes changes to bring AWS in line with code.
        terraform plan -refresh-only only queries AWS and proposes updating the state file.

Q2: What is the risk of running terraform apply -refresh-only blindly?
Answer: If an attacker added 0.0.0.0/0 on SSH, running -refresh-only would accept that
        malicious change into state instead of wiping it out.

---

## 7. Cost & Security Review
- Cost: Security Groups have $0.00 charges in AWS
- Security: Never leave 0.0.0.0/0 open on management ports
```

---

---

# 📥 Part 6 — Lab 02: Resource Import (Bring a Rogue Resource Under Control)

> **🧑‍🍳 Layman Explanation:**
> Someone created an SQS queue manually in the AWS Console during an emergency.
> Now you need to tell Terraform: "Hey, this thing already exists — don't create a new one,
> just start tracking it in your memory (state) going forward."
>
> It's like adopting a stray cat — the cat already exists, you just need to register it
> at the vet under your name. You don't create a new cat!

---

### 📄 `labs/02-resource-import/README.md`

```markdown
# Lab 02 – Importing Existing AWS Resources

## 1. Real-World Production Incident
**Incident Ticket #INC-1022:**
*Summary:* An SQS dead-letter queue was provisioned manually via AWS Console during a production hotfix.
The team now requires all infrastructure to be 100% Terraform-managed.
We must bring the queue into state WITHOUT destroying or recreating it (active messages are in flight).

---

## 2. Concept & Methods
Terraform offers two approaches to importing:
1. Modern Declarative import block (Terraform 1.5+): Code-first, reviewable in pull requests
2. Traditional CLI terraform import: Imperative command updating state directly

### Modern Import Block (Recommended)

import {
  to = aws_sqs_queue.orders_dlq
  id = "https://sqs.ap-southeast-1.amazonaws.com/352458843311/p05-unmanaged-orders-dlq"
}

resource "aws_sqs_queue" "orders_dlq" {
  name                      = "p05-unmanaged-orders-dlq"
  message_retention_seconds = 86400
}

---

## 3. Terminal Execution Sequence
1. Create target SQS queue in AWS Console or via AWS CLI
2. Add the import block and matching resource block
3. Run terraform plan:
   Expected: Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
4. Run terraform apply:
   Imports the resource directly into S3 remote state
```

---

---

# 🔀 Part 7 — Lab 03: Refactoring (Reorganize Without Destroying)

> **🧑‍🍳 Layman Explanation:**
> You have a server defined directly in your main file as `aws_instance.web`.
> Your team wants to move it into a reusable module (`modules/ec2`).
>
> If you just delete the old code and add the module, Terraform thinks:
> *"The old thing is gone → DESTROY IT. The new thing appeared → CREATE IT."*
> That means your production server gets killed and rebuilt — downtime!
>
> The `moved` block is like telling the postal service:
> *"I changed my address from 123 Old Street to 456 New Avenue — same person, don't send me a new birth certificate."*

---

### 📄 `labs/03-refactoring-moved-block/README.md`

```markdown
# Lab 03 – Refactoring with Moved Blocks

## 1. Real-World Production Incident
**Incident Ticket #INC-2045:**
*Summary:* A monolithic config defined aws_instance.web. The team is standardizing on
modules/ec2. Simply changing the address would cause Terraform to DESTROY the production
server and create a new one (causing downtime and data loss).

---

## 2. Solution: The Declarative moved Block (Terraform 1.1+)

moved {
  from = aws_instance.web
  to   = module.ec2.aws_instance.this
}

When you run terraform plan:

  # aws_instance.web has moved to module.ec2.aws_instance.this
    resource "aws_instance" "this" {
        id = "i-0123456789abcdef0"
        # (all attributes preserved)
    }

  Plan: 0 to add, 0 to change, 0 to destroy.

Zero downtime. Zero recreation. The EC2 instance ID stays exactly the same!
```

---

---

# 🆘 Part 8 — Lab 04: Disaster Recovery (Your State File Is Corrupted!)

> **🧑‍🍳 Layman Explanation:**
> The state file is Terraform's memory. If it gets corrupted or deleted, Terraform develops
> **amnesia** — it thinks NOTHING exists in AWS. If you run `apply` now, it tries to create
> duplicate copies of everything — chaos!
>
> This lab teaches you how to recover the state from S3 version history,
> like restoring a Google Doc to a previous version.
>
> The two magic words are:
> - **Lineage** — A unique ID proving "this state belongs to THIS project"
> - **Serial** — A version number (like v1, v2, v3) so Terraform knows which copy is newest

---

### 📄 `labs/04-state-recovery/README.md`

```markdown
# Lab 04 – Terraform State Backup & Disaster Recovery

## 1. Real-World Production Incident
**Incident Ticket #INC-3109:**
*Summary:* A CI/CD pipeline failed midway through a state migration, corrupting the remote
state file. Terraform now throws parse errors or reports all production resources are gone.

---

## 2. Disaster Recovery Checklist
1. Never panic and never run terraform apply on an empty state
   (it will recreate duplicates or orphan live infrastructure)

2. Leverage S3 Bucket Versioning:
   aws s3api list-object-versions \
     --bucket <STATE_BUCKET> \
     --prefix environments/dev/terraform.tfstate \
     --region ap-southeast-1

3. Download the last known good version:
   aws s3api get-object \
     --bucket <STATE_BUCKET> \
     --key environments/dev/terraform.tfstate \
     --version-id "<LAST_KNOWN_GOOD_VERSION_ID>" \
     recovered_state.json

4. Verify Lineage & Serial:
   Every state file has a lineage GUID and an incrementing serial number.

5. Restore using terraform state push:
   terraform state push recovered_state.json
```

---

---

# 🔄 Part 9 — Lab 05: Safe Replacement (Swap a Sick Server Cleanly)

> **🧑‍🍳 Layman Explanation:**
> Your EC2 instance has a corrupted filesystem or compromised kernel. But its Terraform
> configuration hasn't changed, so `terraform apply` says "No changes".
>
> You need a way to tell Terraform: *"I know the config hasn't changed, but please
> destroy this specific server and build me a fresh one."*
>
> `terraform apply -replace` is like telling a car dealership:
> *"I want the exact same model and color, but give me a brand new car off the lot."*
>
> And `create_before_destroy` is like: *"Build me the new car first, let me test drive it,
> THEN take away the old one."* — zero downtime!

---

### 📄 `labs/05-resource-replacement/README.md`

```markdown
# Lab 05 – Safe EC2 Resource Replacement

## 1. Real-World Production Incident
**Incident Ticket #INC-4420:**
*Summary:* An EC2 instance has an unhealthy OS filesystem corruption or compromised kernel,
but its Terraform configuration hasn't changed. Running terraform apply reports No changes.
How do we force a controlled, safe recreation without modifying .tf code?

---

## 2. Command: terraform apply -replace

terraform plan -replace="module.ec2.aws_instance.this" -out=replace_plan.tfplan

Expected Output:
  # module.ec2.aws_instance.this will be replaced, as requested
  -/+ resource "aws_instance" "this" {
        ~ id = "i-old12345" -> (known after apply)
      }
  Plan: 1 to add, 0 to change, 1 to destroy.

Applying the saved plan:
  terraform apply replace_plan.tfplan

---

## 3. Minimizing Downtime: create_before_destroy

lifecycle {
  create_before_destroy = true
}

Terraform launches the new healthy instance FIRST, waits for AWS confirmation,
and only then terminates the old instance.
```

---

---

# 📚 Part 10 — Documentation

> **🧑‍🍳 Layman Explanation:**
> These four docs are your cheat sheets, quick-action cards, and interview prep guides.
> They cover architecture, what to do in emergencies, common errors, and what interviewers ask.

---

### 📄 `docs/architecture.md`

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

**State Locking Architecture:** Starting in Terraform 1.10+, `use_lockfile = true` uses
S3 Object Conditional Writes (`If-None-Match` HTTP headers) to create an atomic lockfile
(`.terraform.tfstate.lock.info`) directly in S3 — no DynamoDB table needed!

---

### 📄 `docs/incident-runbooks.md`

> *Quick-reference action cards for each production incident type:*

| Incident | Step 1 | Step 2 | Step 3 |
|----------|--------|--------|--------|
| **Unauthorized SG Rule** | `terraform plan -refresh-only` to see drift | `terraform apply` to remove rogue rule | Update Git documentation |
| **Unmanaged SQS Queue** | Identify queue URL | Add `import {}` block + `resource {}` block | `terraform apply` (1 to import, 0 to destroy) |
| **Refactoring to Module** | Add `moved { from → to }` block | `terraform plan` (0 add, 0 destroy) | Commit to Git and apply |
| **Corrupted State File** | STOP all pipelines immediately | Download last good version from S3 | `terraform state push recovered.json` |
| **Sick EC2 Instance** | `terraform plan -replace="..."` | Verify only 1 replacement planned | `terraform apply replace.tfplan` |

---

### 📄 `docs/troubleshooting.md`

| Issue / Error | Root Cause | Solution |
|---|---|---|
| `Error acquiring the state lock` | A previous apply crashed or another engineer is running `apply` | Verify no pipeline is running, then `terraform force-unlock <LOCK_ID>` |
| `Resource already exists` during apply | Resource was created manually outside Terraform | Import using `import {}` block or delete the manual resource |
| `Plan proposes destroy and recreate` | A non-updatable argument was changed (e.g., VPC ID) | Check if change is intended or use `create_before_destroy = true` |
| `Provider configuration not present` | Module uses an alias that wasn't passed down | Add `configuration_aliases` and pass the alias from root |

---

### 📄 `docs/interview-questions.md`

> **Q1: How do you detect drift in automated CI/CD?**
> Schedule `terraform plan -refresh-only -detailed-exitcode`. Exit code `2` = drift detected → alert to Slack/PagerDuty.

> **Q2: `terraform state mv` vs `moved` block?**
> `state mv` is imperative, local, risky in teams. `moved` blocks are declarative, tracked in Git, automatically applied by any CI runner.

> **Q3: `use_lockfile = true` vs DynamoDB?**
> Starting in Terraform 1.10+, native S3 conditional writes replace DynamoDB — no extra table, no extra cost, no extra IAM.

> **Q4: Risks of `terraform state push`?**
> Forcefully overwrites remote state. If pushed with wrong serial or lineage, Terraform loses track of real infrastructure. Always back up first.

---

---

# 🧰 Part 11 — Scripts: Automated Checks

> **🧑‍🍳 Layman Explanation:**
> Before a pilot takes off, they run a preflight checklist. These scripts do the same —
> they verify that your tools are installed, your AWS credentials work, and your Terraform
> code has no syntax errors, all before you touch any real infrastructure.

---

### 📄 `scripts/preflight-check.sh` *(Linux / macOS)*

```bash
# Preflight Verification Script (Linux/macOS)
set -euo pipefail

echo "=== [1/4] Checking Terraform Version ==="
terraform version

echo "=== [2/4] Checking AWS CLI Identity ==="
aws sts get-caller-identity --output table

echo "=== [3/4] Verifying Target Region ==="
echo "Configured Region: ap-southeast-1"

echo "=== [4/4] Validating Terraform Code ==="
cd environments/dev
terraform fmt -check -recursive
echo "Preflight checks passed!"
```

---

### 📄 `scripts/preflight-check.ps1` *(Windows PowerShell)*

```powershell
# Preflight Verification Script (Windows PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "=== [1/4] Checking Terraform Version ===" -ForegroundColor Cyan
terraform version

Write-Host "`n=== [2/4] Checking AWS Region & Identity ===" -ForegroundColor Cyan
Write-Host "Configured Target Region: ap-southeast-1"

Write-Host "`n=== [3/4] Validating Terraform Dev Code ===" -ForegroundColor Cyan
Push-Location "environments/dev"
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
Pop-Location

Write-Host "`n✓ Preflight validation completed successfully!" -ForegroundColor Green
```

---

### 📄 `scripts/verify-resources.sh` *(Post-deployment verification)*

```bash
# Resource Verification Script (Linux/macOS)
set -euo pipefail
REGION="ap-southeast-1"

echo "=== Checking Security Groups in $REGION ==="
aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=tag:Lab,Values=terraform-project-05" \
  --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,VpcId:VpcId}" \
  --output table

echo "=== Checking S3 State Buckets in $REGION ==="
aws s3api list-buckets \
  --query "Buckets[?contains(Name, 'p05-tfstate')].Name" \
  --output table
```

---

---

# 🚫 Part 12 — .gitignore: What Git Should Never Track

> **🧑‍🍳 Layman Explanation:**
> Some files are dangerous to commit to Git:
> - `.terraform/` folders contain downloaded provider binaries (huge, platform-specific)
> - `.tfstate` files contain your infrastructure's private details (IP addresses, IDs, secrets)
> - `.tfvars` files may contain passwords or API keys
>
> This `.gitignore` file tells Git: "Pretend these files don't exist."

---

### 📄 `.gitignore`

```text
# Local .terraform directories
**/.terraform/*
**/.terraform/

# .tfstate files
*.tfstate
*.tfstate.*
*.tfstate.backup

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Plan files
*.tfplan
tfplan

# Windows / OS junk
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
.DS_Store
```

---

---

# 📄 Project README

### 📄 `README.md`

```markdown
# Project 05 – Terraform Production Incident Management

A complete, production-grade hands-on laboratory covering advanced Terraform operations,
incident response, drift detection, resource import, refactoring with moved blocks,
and disaster recovery in ap-southeast-1 (Singapore).

## The 5 Production Incident Labs

| Lab | Topic                              | Focus Area                                                |
|-----|------------------------------------|-----------------------------------------------------------|
| 01  | Drift Detection & Remediation      | Identifying out-of-band changes with terraform plan       |
| 02  | Resource Import                    | Terraform 1.5+ declarative import blocks for SQS          |
| 03  | Refactoring with moved Blocks      | Moving resources into modules without destroying them      |
| 04  | Disaster Recovery                  | Restoring corrupted state using S3 version history         |
| 05  | Controlled Resource Replacement    | Replacing unhealthy EC2 instances safely                   |

## Project Structure

terraform-project-05/
├── bootstrap/           # S3 remote state bucket
├── environments/dev/    # Dev environment with native S3 locking
├── modules/ec2/         # Reusable EC2 module
├── labs/                # 5 comprehensive incident runbooks
├── scripts/             # Preflight & verification scripts
├── docs/                # Architecture, runbooks, troubleshooting, interviews
└── README.md
```

---

> **End of Consolidated Single File — All 28 files from `terraform-project-05/`**
