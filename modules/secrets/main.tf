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

# Database credentials secret
resource "aws_secretsmanager_secret" "database" {
  count = var.create_resources ? 1 : 0

  name        = "/tf-playground/${var.environment}/database/credentials-${random_id.secret_suffix[0].hex}"
  description = "Database credentials for ${var.environment} environment"

  tags = {
    Name        = "${var.environment}-database-secret"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Random suffix to avoid deletion conflicts
resource "random_id" "secret_suffix" {
  count = var.create_resources ? 1 : 0

  byte_length = 8
}

# Database credentials secret version
resource "aws_secretsmanager_secret_version" "database" {
  count = var.create_resources ? 1 : 0

  secret_id = aws_secretsmanager_secret.database[0].id
  secret_string = jsonencode({
    username = "tfplayground_user"
    password = random_password.db_password[0].result
  })
}

# Random database password
resource "random_password" "db_password" {
  count = var.create_resources ? 1 : 0

  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# SSH Key Pair (using Secrets Manager)
resource "aws_key_pair" "managed" {
  count = var.ssh_public_key_secret_name != null ? 1 : 0

  key_name   = "${var.environment}-managed-key"
  public_key = data.aws_secretsmanager_secret_version.ssh_public[0].secret_string

  tags = {
    Name        = "${var.environment}-managed-key"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Database password from Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  count = var.db_password_secret_name != null ? 1 : 0

  secret_id = var.db_password_secret_name
}

# Data source for SSH public key
data "aws_secretsmanager_secret_version" "ssh_public" {
  count = var.ssh_public_key_secret_name != null ? 1 : 0

  secret_id = var.ssh_public_key_secret_name
}

# Data source for SSH private key (for outputs)
data "aws_secretsmanager_secret_version" "ssh_private" {
  count = var.ssh_private_key_secret_name != null ? 1 : 0

  secret_id = var.ssh_private_key_secret_name
}

 