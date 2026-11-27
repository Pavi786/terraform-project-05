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
