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
      Pipeline    = "gitflow-cicd"
      Tier        = "production"
    }
  }
}

# Remote state data source for global OIDC provider
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "tf-playground-state-vexus"
    key    = "global/terraform.tfstate"
    region = "us-east-2"
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

# Centralized Secrets Configuration
# These can be changed to environment-specific secrets if needed
locals {
  # Secret paths - can be changed to environment-specific if needed
  db_password_secret_name     = "/tf-playground/all/db-pword"
  ssh_private_key_secret_name = "/tf-playground/all/ssh-key"
  ssh_public_key_secret_name  = "/tf-playground/all/ssh-key-public"
}

# Get centralized database password
data "aws_secretsmanager_secret" "db_password" {
  name = local.db_password_secret_name
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

# Get centralized SSH private key
data "aws_secretsmanager_secret" "ssh_private" {
  name = local.ssh_private_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_private" {
  secret_id = data.aws_secretsmanager_secret.ssh_private.id
}

# Get centralized SSH public key
data "aws_secretsmanager_secret" "ssh_public" {
  name = local.ssh_public_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_public" {
  secret_id = data.aws_secretsmanager_secret.ssh_public.id
}

# Create environment-specific AWS key pair using centralized SSH public key
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

# Application Load Balancer Module
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnets    = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  security_group_id = module.networking.alb_security_group_id
  waf_web_acl_arn   = data.terraform_remote_state.global.outputs.waf_web_acl_arn
}

# Database Module
module "database" {
  source            = "../../modules/database"
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnet_ids
  db_instance_type  = var.db_instance_type
  db_name           = var.db_name
  db_username       = "tfplayground_user"
  db_password       = data.aws_secretsmanager_secret_version.db_password.secret_string
  security_group_id = module.networking.database_security_group_id
}

# Blue Auto Scaling Group
module "blue_asg" {
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "blue"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = module.loadbalancer.alb_security_group_id
  target_group_arn      = module.loadbalancer.blue_target_group_arn
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.blue_desired_capacity
  max_size              = var.blue_max_size
  min_size              = var.blue_min_size
  db_host               = module.database.db_instance_address
  db_name               = var.db_name
  db_user               = "tfplayground_user"
  db_password           = data.aws_secretsmanager_secret_version.db_password.secret_string
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = aws_key_pair.environment_key.key_name
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
}

# Green Auto Scaling Group
module "green_asg" {
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "green"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = module.loadbalancer.alb_security_group_id
  target_group_arn      = module.loadbalancer.green_target_group_arn
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.green_desired_capacity
  max_size              = var.green_max_size
  min_size              = var.green_min_size
  db_host               = module.database.db_instance_address
  db_name               = var.db_name
  db_user               = "tfplayground_user"
  db_password           = data.aws_secretsmanager_secret_version.db_password.secret_string
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = aws_key_pair.environment_key.key_name
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
}

# SSM Module for Database Bootstrapping (updated to use blue ASG)
module "ssm" {
  source                = "../../modules/ssm"
  environment           = var.environment
  webserver_instance_id = module.blue_asg.asg_id           # Will need to get actual instance ID
  webserver_public_ip   = module.loadbalancer.alb_dns_name # Use ALB DNS name instead
  database_endpoint     = module.database.db_instance_address
  database_name         = var.db_name
  database_username     = "tfplayground_user"
  database_password     = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# Logging Module
module "logging" {
  source = "../../modules/logging"

  environment    = var.environment
  aws_region     = var.aws_region
  alb_name       = module.loadbalancer.alb_name
  alb_identifier = module.loadbalancer.alb_identifier

  # Use log group names from global environment
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
  alarm_log_group_name       = data.terraform_remote_state.global.outputs.alarm_log_groups[var.environment]
}

# OIDC Module removed - using global GitHub Actions role instead
# The global environment manages the OIDC provider and GitHub Actions role
# Staging and production environments use the global role via CI/CD workflows 