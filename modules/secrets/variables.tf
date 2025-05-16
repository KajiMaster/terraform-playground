variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "db_username" {
  description = "Initial database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Initial database master password"
  type        = string
  sensitive   = true
} 