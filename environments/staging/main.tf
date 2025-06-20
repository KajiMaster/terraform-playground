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

  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  azs           = var.availability_zones
}

# Secrets Management Module
module "secrets" {
  source           = "../../modules/secrets"
  environment      = var.environment
  create_resources = true
}

# Database Module
module "database" {
  source                      = "../../modules/database"
  environment                 = var.environment
  vpc_id                      = module.networking.vpc_id
  private_subnets             = module.networking.private_subnet_ids
  webserver_security_group_id = module.webserver.security_group_id
  db_instance_type            = var.db_instance_type
  db_name                     = var.db_name
  db_username                 = module.secrets.db_username
  db_password                 = module.secrets.db_password
}

# Compute Module (Web Server)
module "webserver" {
  source = "../../modules/compute/webserver"

  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  instance_type  = var.webserver_instance_type
  key_name       = var.key_name
  db_host        = module.database.db_instance_endpoint
  db_name        = module.database.db_instance_name
  db_user        = module.secrets.db_username
  db_password    = module.secrets.db_password
}

# SSM Module
module "ssm" {
  source = "../../modules/ssm"

  environment           = var.environment
  webserver_instance_id = module.webserver.instance_id
  webserver_public_ip   = module.webserver.public_ip
  database_endpoint     = module.database.db_instance_endpoint
  database_name         = module.database.db_instance_name
  database_username     = module.secrets.db_username
  database_password     = module.secrets.db_password
  ssh_key_path          = var.ssh_key_path
  ssh_user              = var.ssh_user
}

# OIDC Module for GitHub Actions
module "oidc" {
  source = "../../modules/oidc"

  environment          = var.environment
  github_repository    = "KajiMaster/terraform-playground"
  create_oidc_provider = false
  state_bucket         = var.state_bucket
  state_lock_table     = var.state_lock_table
  aws_region           = var.aws_region
} 