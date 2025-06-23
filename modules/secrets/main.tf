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

# Random suffix for unique resource names (avoids deletion recovery window conflicts)
resource "random_string" "suffix" {
  count   = var.create_resources ? 1 : 0
  length  = 4
  special = false
  upper   = false
}

# Conditional secret creation (using AWS default encryption)
resource "aws_secretsmanager_secret" "db_credentials" {
  count       = var.create_resources ? 1 : 0
  name        = "/tf-playground/${var.environment}/database/credentials-${random_string.suffix[0].result}"
  description = "Database credentials for ${var.environment} environment"
  # Removed kms_key_id - will use AWS default encryption

  tags = {
    Name        = "tf-playground-${var.environment}-db-credentials-${random_string.suffix[0].result}"
    Environment = var.environment
    Project     = "tf-playground"
  }
}

# Data source for existing secret (when not creating)
data "aws_secretsmanager_secret" "db_credentials" {
  count = var.create_resources ? 0 : 1
  name  = "/tf-playground/${var.environment}/database/credentials"
}

# Conditional secret version creation
resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.create_resources ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = "tfplayground_user"
    password = random_password.db_password[0].result
  })
}

# Data source for existing secret version (when not creating)
data "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.create_resources ? 0 : 1
  secret_id = data.aws_secretsmanager_secret.db_credentials[0].id
}

# Conditional random password generation
resource "random_password" "db_password" {
  count   = var.create_resources ? 1 : 0
  length  = 16
  special = true
} 