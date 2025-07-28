variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "ecr_repository_url" {
  description = "External ECR repository URL (from global environment)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS resources will be created"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "database_security_group_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "blue_target_group_arn" {
  description = "ARN of the blue target group"
  type        = string
}

variable "green_target_group_arn" {
  description = "ARN of the green target group"
  type        = string
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "tfplayground_user"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "tfplayground"
}

variable "application_log_group_name" {
  description = "CloudWatch log group name for application logs"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory for ECS tasks in MiB"
  type        = number
  default     = 1024
}

variable "blue_desired_count" {
  description = "Desired number of blue service tasks"
  type        = number
  default     = 1
}

variable "green_desired_count" {
  description = "Desired number of green service tasks"
  type        = number
  default     = 0
} 