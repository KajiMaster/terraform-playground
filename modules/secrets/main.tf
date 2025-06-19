terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Create KMS key for secrets encryption
resource "aws_kms_key" "secrets" {
  description             = "KMS key for ${var.environment} secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "tf-playground-${var.environment}-secrets"
    Environment = var.environment
    Project     = "tf-playground"
  }
}

# Create KMS alias
resource "aws_kms_alias" "secrets" {
  name          = "alias/tf-playground-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Create the secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "/tf-playground/${var.environment}/database/credentials"
  description = "Database credentials for ${var.environment} environment"
  kms_key_id  = aws_kms_key.secrets.arn

  tags = {
    Name        = "tf-playground-${var.environment}-db-credentials"
    Environment = var.environment
    Project     = "tf-playground"
  }
}

# Create the secret version with initial credentials
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "tfplayground_user"
    password = random_password.db_password.result
  })
}

# Generate a random password
resource "random_password" "db_password" {
  length  = 16
  special = true
}

output "db_username" {
  description = "The database username"
  value       = "tfplayground_user"
}

output "db_password" {
  description = "The database password"
  value       = random_password.db_password.result
  sensitive   = true
} 