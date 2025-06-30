# Staging environment variables
# Managed by GitFlow CI/CD pipeline
# COST OPTIMIZED: Using smallest viable resources for lab environment

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
  description = "Instance type for web server (cost optimized for lab)"
  type        = string
  default     = "t3.micro"  # Changed from t3.small to t3.micro
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "tf-playground-staging"
}

variable "db_instance_type" {
  description = "Instance type for RDS (cost optimized for lab)"
  type        = string
  default     = "db.t3.micro"  # Changed from db.t3.small to db.t3.micro
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

# Blue-Green Deployment Variables

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-06c8f2ec674c67112"  # Amazon Linux 2023 AMI in us-east-2 (same as dev)
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = null  # No SSL for staging demo
}

# Blue Environment Configuration (cost optimized)
variable "blue_desired_capacity" {
  description = "Desired capacity for blue Auto Scaling Group"
  type        = number
  default     = 1
}

variable "blue_max_size" {
  description = "Maximum size for blue Auto Scaling Group"
  type        = number
  default     = 1  # Reduced from 2 to 1 for cost savings
}

variable "blue_min_size" {
  description = "Minimum size for blue Auto Scaling Group"
  type        = number
  default     = 1
}

# Green Environment Configuration (cost optimized)
variable "green_desired_capacity" {
  description = "Desired capacity for green Auto Scaling Group"
  type        = number
  default     = 0  # Start with 0 to save costs, scale up only when needed
}

variable "green_max_size" {
  description = "Maximum size for green Auto Scaling Group"
  type        = number
  default     = 1  # Reduced from 2 to 1 for cost savings
}

variable "green_min_size" {
  description = "Minimum size for green Auto Scaling Group"
  type        = number
  default     = 0  # Start with 0 to save costs
} 