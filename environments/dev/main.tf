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
