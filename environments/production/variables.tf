# Production environment variables
# Managed by GitFlow CI/CD pipeline
# UPDATED: Blue-Green Deployment Architecture (Cost Optimized for Demo)

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "webserver_instance_type" {
  description = "EC2 instance type for web server (cost optimized for demo)"
  type        = string
  default     = "t3.micro"  # Cost optimized - same as staging
}

variable "db_instance_type" {
  description = "RDS instance type (cost optimized for demo)"
  type        = string
  default     = "db.t3.micro"  # Cost optimized - same as staging
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "tfplayground_prod"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "tf-playground-production"
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/tf-playground-production.pem"
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
  default     = "ami-06c8f2ec674c67112" # Amazon Linux 2023 AMI in us-east-2
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = null # No SSL for production demo
}

# Blue Environment Configuration (cost optimized for demo)
variable "blue_desired_capacity" {
  description = "Desired capacity for blue Auto Scaling Group"
  type        = number
  default     = 1  # Cost optimized - same as staging
}

variable "blue_max_size" {
  description = "Maximum size for blue Auto Scaling Group"
  type        = number
  default     = 2  # Cost optimized - same as staging
}

variable "blue_min_size" {
  description = "Minimum size for blue Auto Scaling Group"
  type        = number
  default     = 1  # Cost optimized - same as staging
}

# Green Environment Configuration (cost optimized for demo)
variable "green_desired_capacity" {
  description = "Desired capacity for green Auto Scaling Group"
  type        = number
  default     = 1  # Cost optimized - same as staging
}

variable "green_max_size" {
  description = "Maximum size for green Auto Scaling Group"
  type        = number
  default     = 2  # Cost optimized - same as staging
}

variable "green_min_size" {
  description = "Minimum size for green Auto Scaling Group"
  type        = number
  default     = 1  # Cost optimized - same as staging
} 