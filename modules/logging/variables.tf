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

variable "alb_name" {
  description = "ALB name for metrics (CloudWatch LoadBalancer dimension)"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (SNS topics, etc.)"
  type        = list(string)
  default     = []
}

variable "enable_cleanup" {
  description = "Enable automatic log cleanup for demo environments"
  type        = bool
  default     = true
} 