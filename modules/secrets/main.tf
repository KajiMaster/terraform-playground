terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# KMS key for encrypting sensitive values
resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting sensitive Terraform values"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Alias for the KMS key (makes it easier to reference)
resource "aws_kms_alias" "secrets" {
  name          = "alias/tf-playground-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Database credentials in Parameter Store
resource "aws_ssm_parameter" "db_username" {
  name        = "/tf-playground/${var.environment}/database/username"
  description = "Database master username"
  type        = "SecureString"
  value       = var.db_username
  key_id      = aws_kms_key.secrets.key_id

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/tf-playground/${var.environment}/database/password"
  description = "Database master password"
  type        = "SecureString"
  value       = var.db_password
  key_id      = aws_kms_key.secrets.key_id

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
} 