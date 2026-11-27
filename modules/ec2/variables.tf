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
