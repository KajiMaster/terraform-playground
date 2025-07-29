# Universal Environment Variables
# This file can be used across all environments (dev, staging, production)
# Environment-specific values are set via terraform.tfvars or environment variables

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
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
  description = "Instance type for web server (cost optimized)"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for RDS (cost optimized)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "tfplayground"
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = null
}

# Blue-Green Deployment Variables
variable "blue_desired_capacity" {
  description = "Desired capacity for blue Auto Scaling Group"
  type        = number
  default     = 1
}

variable "blue_max_size" {
  description = "Maximum size for blue Auto Scaling Group"
  type        = number
  default     = 2
}

variable "blue_min_size" {
  description = "Minimum size for blue Auto Scaling Group"
  type        = number
  default     = 1
}

variable "green_desired_capacity" {
  description = "Desired capacity for green Auto Scaling Group"
  type        = number
  default     = 1
}

variable "green_max_size" {
  description = "Maximum size for green Auto Scaling Group"
  type        = number
  default     = 2
}

variable "green_min_size" {
  description = "Minimum size for green Auto Scaling Group"
  type        = number
  default     = 1
}

# WAF Configuration
variable "environment_waf_use" {
  description = "Use WAF for this environment"
  type        = bool
  default     = true
}

# ECS Migration Variables
variable "disable_asg" {
  description = "Disable ASG and use ECS only"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable ECS deployment"
  type        = bool
  default     = false
}

variable "blue_ecs_desired_count" {
  description = "Desired number of blue ECS service tasks"
  type        = number
  default     = 1
}

variable "green_ecs_desired_count" {
  description = "Desired number of green ECS service tasks"
  type        = number
  default     = 0
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-06c8f2ec674c67112" # Amazon Linux 2023 AMI in us-east-2
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway (cost consideration)"
  type        = bool
  default     = true
} 