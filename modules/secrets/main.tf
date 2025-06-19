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

# Conditional KMS key creation
resource "aws_kms_key" "secrets" {
  count                   = var.create_resources ? 1 : 0
  description             = "KMS key for ${var.environment} secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "tf-playground-${var.environment}-secrets"
    Environment = var.environment
    Project     = "tf-playground"
  }
}

# Conditional KMS alias creation
resource "aws_kms_alias" "secrets" {
  count         = var.create_resources ? 1 : 0
  name          = "alias/tf-playground-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

# Data source for existing KMS key (when not creating)
data "aws_kms_key" "secrets" {
  count  = var.create_resources ? 0 : 1
  key_id = "alias/tf-playground-${var.environment}-secrets"
}

# Conditional secret creation
resource "aws_secretsmanager_secret" "db_credentials" {
  count       = var.create_resources ? 1 : 0
  name        = "/tf-playground/${var.environment}/database/credentials"
  description = "Database credentials for ${var.environment} environment"
  kms_key_id  = aws_kms_key.secrets[0].arn

  tags = {
    Name        = "tf-playground-${var.environment}-db-credentials"
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
  count         = var.create_resources ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db_credentials[0].id
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

# Outputs that work with both modes
output "db_username" {
  description = "The database username"
  value       = var.create_resources ? "tfplayground_user" : jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string)["username"]
}

output "db_password" {
  description = "The database password"
  value       = var.create_resources ? random_password.db_password[0].result : jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string)["password"]
  sensitive   = true
} 