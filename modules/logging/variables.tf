variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "log_retention_days" {
  description = "Number of days to retain logs (demo: 1 day)"
  type        = number
  default     = 1
}

variable "application_log_group_name" {
  description = "Application log group name from global environment"
  type        = string
}

variable "system_log_group_name" {
  description = "System log group name from global environment"
  type        = string
}

variable "alarm_log_group_name" {
  description = "Alarm log group name from global environment"
  type        = string
}

variable "alb_name" {
  description = "ALB name for metrics (CloudWatch LoadBalancer dimension)"
  type        = string
}

variable "alb_identifier" {
  description = "Full ALB identifier for CloudWatch metrics (e.g., app/staging-alb/00157f7cffd3b5e8)"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (SNS topics, etc.)"
  type        = list(string)
  default     = []
}

 