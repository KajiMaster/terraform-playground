terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use centralized SSH keys from Secrets Manager
data "aws_secretsmanager_secret" "ssh_private" {
  name = var.ssh_private_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_private" {
  secret_id = data.aws_secretsmanager_secret.ssh_private.id
}

data "aws_secretsmanager_secret" "ssh_public" {
  name = var.ssh_public_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_public" {
  secret_id = data.aws_secretsmanager_secret.ssh_public.id
}

# Create environment-specific AWS key pair using the centralized public key
resource "aws_key_pair" "environment_key" {
  key_name   = "tf-playground-${var.environment}-key"
  public_key = data.aws_secretsmanager_secret_version.ssh_public.secret_string

  tags = {
    Name        = "tf-playground-${var.environment}-key"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "centralized-ssh-key"
  }
} 