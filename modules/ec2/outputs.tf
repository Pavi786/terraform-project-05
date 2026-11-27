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
