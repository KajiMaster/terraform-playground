variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-06c8f2ec674c67112" # Amazon Linux 2023 AMI in us-east-2 (updated June 2025)
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the instance. This key pair must exist in AWS and be managed separately from Terraform."
  type        = string
}

variable "db_host" {
  description = "Database host address"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  description = "Security group ID for the web server (managed by networking module)"
  type        = string
} 