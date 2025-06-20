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
      Environment = "${var.environment}"
      Project     = "tf-playground"
      ManagedBy   = "terraform"
    }
  }
}

# Remote state data source for global OIDC provider
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket         = "tf-playground-state-vexus"
    key            = "global/terraform.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
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
  source          = "../../modules/secrets"
  environment     = var.environment
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
  source         = "../../modules/compute/webserver"
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  instance_type  = var.webserver_instance_type
  key_name       = var.key_name
  db_host        = module.database.db_instance_address
  db_name        = var.db_name
  db_user        = module.secrets.db_username
  db_password    = module.secrets.db_password
}

# SSM Module for Database Bootstrapping
module "ssm" {
  source                = "../../modules/ssm"
  environment           = var.environment
  webserver_instance_id = module.webserver.instance_id
  webserver_public_ip   = module.webserver.public_ip
  database_endpoint     = module.database.db_instance_address
  database_name         = var.db_name
  database_username     = module.secrets.db_username
  database_password     = module.secrets.db_password
}

# OIDC Module for GitHub Actions (references existing global provider)
module "oidc" {
  source = "../../modules/oidc"

  environment         = var.environment
  github_repository   = "KajiMaster/terraform-playground"
  state_bucket        = "tf-playground-state-vexus"
  state_lock_table    = "tf-playground-locks"
  aws_region          = var.aws_region
  create_oidc_provider = false  # Reference existing provider
} 