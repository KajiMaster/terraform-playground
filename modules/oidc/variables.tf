variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name (format: owner/repo)"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "state_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "create_oidc_provider" {
  description = "Whether to create a new OIDC provider or reference existing one"
  type        = bool
  default     = true
} 