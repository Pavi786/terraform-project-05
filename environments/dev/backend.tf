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
