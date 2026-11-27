# Consolidated Terraform Code Reference - Project 05

This single document contains **all Terraform source code** across the entire project structure:
1. **Bootstrap Module** (`bootstrap/`) - Creates S3 remote backend bucket with native locking, versioning, encryption, and public block.
2. **Dev Environment** (`environments/dev/`) - Configures AWS provider, remote S3 backend, and Lab resources.
3. **EC2 Reusable Module** (`modules/ec2/`) - EC2 instance configuration with dynamic AMI discovery, IMDSv2, and encrypted storage.

---

## 1. Bootstrap Remote State Module

### 1.1 `bootstrap/main.tf`
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
  force_destroy = false # Safety constraint: Protect production state from accidental deletion

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

### 1.2 `bootstrap/variables.tf`
```hcl
variable "aws_region" {
  description = "Target AWS region for Project 05"
  type        = string
  default     = "ap-southeast-1"
}
```

### 1.3 `bootstrap/outputs.tf`
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

## 2. Dev Environment

### 2.1 `environments/dev/versions.tf`
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

### 2.2 `environments/dev/provider.tf`
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "terraform-project-05"
    }
  }
}
```

### 2.3 `environments/dev/backend.tf`
```hcl
# Remote S3 Backend with Native S3 Locking (Terraform 1.10+)
# Notice: 'use_lockfile = true' enables native S3 concurrency locking without needing DynamoDB!
terraform {
  backend "s3" {
    bucket       = "p05-tfstate-352458843311-ap-southeast-1"
    key          = "environments/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### 2.4 `environments/dev/main.tf`
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

### 2.5 `environments/dev/variables.tf`
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

### 2.6 `environments/dev/outputs.tf`
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

### 2.7 `environments/dev/terraform.tfvars.example`
```hcl
aws_region        = "ap-southeast-1"
project_name      = "p05-incident-mgmt"
environment       = "dev"
allowed_test_cidr = "10.0.0.0/16"
instance_type     = "t3.micro"
```

---

## 3. EC2 Reusable Module

### 3.1 `modules/ec2/versions.tf`
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

### 3.2 `modules/ec2/main.tf`
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

### 3.3 `modules/ec2/variables.tf`
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

### 3.4 `modules/ec2/outputs.tf`
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
