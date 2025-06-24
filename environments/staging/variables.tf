# Staging environment variables
# Managed by GitFlow CI/CD pipeline
# TESTING: Workflow trigger - June 2025

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "webserver_instance_type" {
  description = "Instance type for web server (staging test)"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "tf-playground-staging"
}

variable "db_instance_type" {
  description = "Instance type for RDS"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "tfplayground"
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/tf-playground-staging.pem"
}

variable "ssh_user" {
  description = "SSH user for EC2 instance"
  type        = string
  default     = "ec2-user"
}

variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "tf-playground-state-vexus"
}

variable "state_lock_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "tf-playground-locks"
} 