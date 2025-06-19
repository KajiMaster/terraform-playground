variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (false if it already exists)"
  type        = bool
  default     = false
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "tf-playground-state-vexus"
}

variable "state_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "tf-playground-locks"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
} 