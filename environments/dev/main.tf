terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # We'll configure the backend when we set up Terraform Cloud
  # backend "remote" {
  #   organization = "your-org"
  #   workspaces {
  #     name = "tf-playground-${var.environment}"
  #   }
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "tf-playground"
      ManagedBy   = "terraform"
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

# Network Module
module "networking" {
  source = "../../modules/networking"

  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_cidrs    = var.public_subnet_cidrs
  private_cidrs   = var.private_subnet_cidrs
  azs             = var.availability_zones
}

# Secrets Management Module
module "secrets" {
  source = "../../modules/secrets"

  environment  = var.environment
  db_username  = var.initial_db_username
  db_password  = var.initial_db_password
}

# Database Module
module "database" {
  source = "../../modules/database"

  environment               = var.environment
  vpc_id                   = module.networking.vpc_id
  private_subnets          = module.networking.private_subnet_ids
  webserver_security_group_id = module.webserver.security_group_id
  db_instance_type         = var.db_instance_type
  db_name                  = var.db_name
  db_username_parameter    = "/tf-playground/${var.environment}/database/username"
  db_password_parameter    = "/tf-playground/${var.environment}/database/password"
  kms_key_id              = aws_kms_key.secrets.key_id
}

# Compute Module (Web Server)
module "webserver" {
  source = "../../modules/compute/webserver"

  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  instance_type   = var.webserver_instance_type
  key_name        = var.key_name
  db_host         = module.database.db_instance_address
  db_name         = var.db_name
  db_username_parameter = "/tf-playground/${var.environment}/database/username"
  db_password_parameter = "/tf-playground/${var.environment}/database/password"
  kms_key_id      = aws_kms_key.secrets.key_id
} 