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
variable "enable_asg" {
  description = "Enable Auto Scaling Groups (disable when using ECS or EKS)"
  type        = bool
  default     = true
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

# Feature flags for cost optimization
variable "enable_private_subnets" {
  description = "Enable private subnets and NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (requires private subnets)"
  type        = bool
  default     = true
}



# EKS Configuration Variables
variable "enable_eks" {
  description = "Enable EKS cluster"
  type        = bool
  default     = false
}

variable "enable_node_groups" {
  description = "Enable managed node groups (cheaper than Fargate)"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Enable Fargate profiles (more expensive but serverless)"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for EKS"
  type        = bool
  default     = false
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

# Node group configuration
variable "node_group_instance_types" {
  description = "Instance types for node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

# Flask Application Variables
variable "flask_app_replicas" {
  description = "Number of Flask app replicas"
  type        = number
  default     = 1
}

variable "flask_memory_request" {
  description = "Memory request for Flask app containers"
  type        = string
  default     = "64Mi"
}

variable "flask_memory_limit" {
  description = "Memory limit for Flask app containers"
  type        = string
  default     = "128Mi"
}

variable "flask_cpu_request" {
  description = "CPU request for Flask app containers"
  type        = string
  default     = "50m"
}

variable "flask_cpu_limit" {
  description = "CPU limit for Flask app containers"
  type        = string
  default     = "100m"
}

variable "image_tag" {
  description = "Docker image tag for Flask app"
  type        = string
  default     = "latest"
}

# Serverless Architecture Toggle Variables
variable "enable_rds" {
  description = "Enable RDS database resources (disable for serverless architectures)"
  type        = bool
  default     = true
}

variable "enable_platform" {
  description = "Enable platform resources (ASG/ECS/EKS/ALB - disable for pure serverless)"
  type        = bool
  default     = true
} 