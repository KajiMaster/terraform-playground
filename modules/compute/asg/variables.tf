variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "deployment_color" {
  description = "Deployment color (blue or green)"
  type        = string
  validation {
    condition     = contains(["blue", "green"], var.deployment_color)
    error_message = "Deployment color must be either 'blue' or 'green'."
  }
}

variable "vpc_id" {
  description = "VPC ID for the Auto Scaling Group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB to allow traffic from"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group to attach instances to"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-06c8f2ec674c67112" # Amazon Linux 2023 AMI in us-east-2
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
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

variable "health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for auto scaling"
  type        = number
  default     = 80
}

variable "security_group_id" {
  description = "Security group ID for the ASG instances (managed by networking module)"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use for instances"
  type        = string
  default     = null
}

variable "application_log_group_name" {
  description = "Application log group name from global environment"
  type        = string
}

variable "system_log_group_name" {
  description = "System log group name from global environment"
  type        = string
}