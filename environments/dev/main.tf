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
  environment = var.environment
}

# Database Module (updated to "consume" the decrypted db credentials (db_username and db_password) from the secrets module.)
module "database" {
  source = "../../modules/database"
  environment = var.environment
  vpc_id = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  webserver_security_group_id = module.webserver.security_group_id
  db_instance_type = var.db_instance_type
  db_name = var.db_name
  db_username = module.secrets.db_username
  db_password = module.secrets.db_password
}

# Compute Module (Web Server) (updated to "consume" the decrypted db credentials (db_username and db_password) from the secrets module.)
module "webserver" {
  source = "../../modules/compute/webserver"
  environment = var.environment
  vpc_id = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  instance_type = var.webserver_instance_type
  key_name = var.key_name
  db_host = module.database.db_instance_address
  db_name = var.db_name
  db_user = module.secrets.db_username
  db_password = module.secrets.db_password
} 