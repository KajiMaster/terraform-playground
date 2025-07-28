variable "environment" {
  description = "Environment name (e.g., global, staging, production)"
  type        = string
}

variable "app_name" {
  description = "Application name for the ECR repository"
  type        = string
  default     = "flask-app"
}

variable "tags" {
  description = "Additional tags for the ECR repository"
  type        = map(string)
  default     = {}
} 