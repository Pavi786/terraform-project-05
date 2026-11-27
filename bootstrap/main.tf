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
