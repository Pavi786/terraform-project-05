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
