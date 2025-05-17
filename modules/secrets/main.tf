terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reference existing KMS key by alias
data "aws_kms_key" "secrets" {
  key_id = "alias/tf-playground-${var.environment}-secrets"
}

# Reference existing secret
data "aws_secretsmanager_secret" "db_credentials" {
  name = "/tf-playground/${var.environment}/database/credentials"
}

# Get the secret value
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# Parse the secret value
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

output "db_username" {
  description = "The database username from AWS Secrets Manager"
  value       = local.db_credentials["username"]
}

output "db_password" {
  description = "The database password from AWS Secrets Manager"
  value       = local.db_credentials["password"]
  sensitive   = true
} 