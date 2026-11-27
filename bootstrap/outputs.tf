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
